#!/bin/bash
# Helper script for managing temporary hibernation swap file
set -e

SWAP_DIR="/home"
SWAP_FILE="$SWAP_DIR/hibernation.swapfile"
METADATA_FILE="$SWAP_DIR/.hibernation.metadata"

cleanup_swap_on_error() {
	local swap_file="$1"

	swapoff "$swap_file" || true
	rm -f "$swap_file"

	exit 1
}

write_resume_parameters() {
	local swap_file="$1"
	local old_resume="$2"

	BACKING_DEVICE=$(findmnt -no SOURCE -T "$swap_file" 2>/dev/null)
	if [ -z "$BACKING_DEVICE" ]; then
		echo "Error: Failed to find backing device for $swap_file" >&2
		cleanup_swap_on_error "$swap_file"
	fi

	OFFSET=$(filefrag -v "$swap_file" 2>/dev/null | awk '$1=="0:" {print $4}' | tr -d '.')
	if [ -z "$OFFSET" ]; then
		echo "Error: Failed to get offset information for $swap_file" >&2
		cleanup_swap_on_error "$swap_file"
	fi

	if ! echo "$BACKING_DEVICE" > /sys/power/resume; then
		echo "Error: Failed to set resume device to $BACKING_DEVICE" >&2
		cleanup_swap_on_error "$swap_file"
	fi

	if ! echo "$OFFSET" > /sys/power/resume_offset; then
		echo "Error: Failed to set resume offset to $OFFSET" >&2
		echo "$old_resume" > /sys/power/resume 2>/dev/null || true
		cleanup_swap_on_error "$swap_file"
	fi
}

check_existing_swap() {
	local required_size="$1"
	local old_resume="$2"
	
	LARGEST_FILENAME=""
	LARGEST_SWAP=0
	while read -r device type size used priority; do
		# Skip header line
		if [ "$device" = "Filename" ]; then
			continue
		fi

		if [[ "$device" == *"/dev/zram"* ]]; then
			continue
		fi

		if [ "$size" -gt "$LARGEST_SWAP" ]; then
			LARGEST_FILENAME=$device
			LARGEST_SWAP=$size
		fi
	done < /proc/swaps

	if [ "$required_size" -le "$LARGEST_SWAP" ]; then
		echo "Existing swap sufficient (required: $required_size KB, available: $LARGEST_SWAP KB)"
		write_resume_parameters "$LARGEST_FILENAME" "$old_resume"
		exit 0
	fi
}

create_swap() {
	# Use 40% of the active memory size as the swap size
	TOTAL_MEM=$(awk '/^MemTotal: / {print $2}' /proc/meminfo)
	REQUIRED_SIZE=$(( TOTAL_MEM * 40 / 100 ))

	OLD_RESUME=$(cat /sys/power/resume 2>/dev/null || echo "0:0")
	OLD_RESUME_OFFSET=$(cat /sys/power/resume_offset 2>/dev/null || echo "0")

	check_existing_swap "$REQUIRED_SIZE" "$OLD_RESUME"

	# Check if there's enough space in the target directory
	AVAILABLE_SPACE=$(df -k "$SWAP_DIR" | awk 'NR==2 {print $4}')
	if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SIZE" ]; then
		echo "Error: Not enough space in $SWAP_DIR (need ${REQUIRED_SIZE}KB, have ${AVAILABLE_SPACE}KB)" >&2
		exit 1
	fi

	# If the same name swap file already exists, check its size and reuse it if sufficient
	if [ -f "$SWAP_FILE" ]; then
		EXISTING_SIZE_KB=$(( $(stat -c%s "$SWAP_FILE") / 1024 ))
		if [ "$EXISTING_SIZE_KB" -ge "$REQUIRED_SIZE" ]; then
			echo "Swap file $SWAP_FILE already exists. Reusing."
			if ! swapon -p 1000 "$SWAP_FILE"; then
				echo "Error: Failed to activate existing swap file $SWAP_FILE" >&2
				rm -f "$SWAP_FILE"
			else
				# Don't create metadata file so that cleanup function doesn't remove this swap file
				write_resume_parameters "$SWAP_FILE" "$OLD_RESUME"
				exit 0
			fi
		else
			echo "Swap file $SWAP_FILE exists but is small ($EXISTING_SIZE_KB KB). Removing and recreating."
			rm -f "$SWAP_FILE"
		fi
	fi

	echo "Creating swap file: $REQUIRED_SIZE KB ($(( REQUIRED_SIZE / 1024 )) MB)"

	SWAP_SIZE_MB=$(( REQUIRED_SIZE / 1024 + 1 ))
	if ! mkswap --file "$SWAP_FILE" --size ${SWAP_SIZE_MB}M; then
		echo "Error: Failed to create swap file $SWAP_FILE" >&2
		rm -f "$SWAP_FILE"
		exit 1
	fi

	if ! swapon -p 1000 "$SWAP_FILE"; then
		echo "Error: Failed to activate swap file $SWAP_FILE" >&2
		rm -f "$SWAP_FILE"
		exit 1
	fi

	write_resume_parameters "$SWAP_FILE" "$OLD_RESUME"

	# Save metadata for cleanup
	{
		echo "SWAP_FILE=$SWAP_FILE"
		echo "OLD_RESUME=$OLD_RESUME"
		echo "OLD_RESUME_OFFSET=$OLD_RESUME_OFFSET"
		echo "CREATION_TIME=$(date +%s%6N)"
	} > "$METADATA_FILE"

	chmod 600 "$METADATA_FILE"
	echo "Hibernation configured successfully"
	exit 0
}

cleanup_swap() {
	# Set boot counter to 0 after successful resume
	steamos-bootconf --set boot-attempts 0
	echo "The boot-attempt counter has been reset."

	if [ ! -f "$METADATA_FILE" ]; then
		echo "No hibernation swap metadata found"
		exit 0
	fi

	if [ ! -r "$METADATA_FILE" ]; then
		echo "Error: Failed to read metadata file $METADATA_FILE" >&2
		exit 1
	fi

	# Safely parse expected variables from metadata file
	while IFS='=' read -r key value; do
		case "$key" in
			'SWAP_FILE') SWAP_FILE="$value" ;;
			'OLD_RESUME') OLD_RESUME="$value" ;;
			'OLD_RESUME_OFFSET') OLD_RESUME_OFFSET="$value" ;;
			'CREATION_TIME') CREATION_TIME="$value" ;;
		esac
	done < "$METADATA_FILE"

	if [ ! -f "$SWAP_FILE" ]; then
		echo "Swap file $SWAP_FILE not found"
		exit 0
	fi

	# Cleanup the swap file
	if grep -q "$SWAP_FILE" /proc/swaps; then
		swapoff "$SWAP_FILE" || true
	fi

	rm -f "$SWAP_FILE"

	# Restore original resume parameters if they were saved
	if [ -n "$OLD_RESUME" ] && ! echo "$OLD_RESUME" > /sys/power/resume; then
		echo "Warning: Failed to restore original resume device" >&2
	fi

	if [ -n "$OLD_RESUME_OFFSET" ] && ! echo "$OLD_RESUME_OFFSET" > /sys/power/resume_offset; then
		echo "Warning: Failed to restore original resume offset" >&2
	fi

	rm -f "$METADATA_FILE"
	exit 0
}

# Main
case "$1" in
	create)
		create_swap
		;;
	cleanup)
		cleanup_swap
		;;
	status)
		if [ ! -f "$METADATA_FILE" ]; then
			echo "Hibernate swap status: INACTIVE"
			exit 0
		fi

		while IFS='=' read -r key value; do
			case "$key" in
				'SWAP_FILE') SWAP_FILE="$value" ;;
				'CREATION_TIME') CREATION_TIME="$value" ;;
			esac
		done < "$METADATA_FILE"

		echo "Swap file: $SWAP_FILE"
		TIMESTAMP_SECONDS="${CREATION_TIME%??????}"
		echo "Creation time: $(date -d @"$TIMESTAMP_SECONDS" 2>/dev/null || echo "Invalid timestamp")"
		
		if [ ! -f "$SWAP_FILE" ]; then
			echo "Warning: metadata exists but swap file is missing"
			exit 0
		fi

		SWAP_SIZE=$(stat -c%s "$SWAP_FILE" 2>/dev/null || echo "0")
		echo "File size: $((SWAP_SIZE / 1024)) KB"

		if grep -q "$SWAP_FILE" /proc/swaps; then
			echo "Swap active: Yes"
		else
			echo "Swap active: No (Warning: file exists but swap is not active)"
		fi
		;;
	*)
		echo "Usage: $0 {create|cleanup|status}"
		exit 1
		;;
esac
