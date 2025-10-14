#!/bin/bash
# Copyright © 2025 Valve Corporation.

# This script is designed to be invoked by systemd-sleep.
# It expects 2 args: <pre|post> and the requested sleep mode

set -eu

declare mod=
declare -ar modlist=(ath11k-pci)
declare op=${2:-${SYSTEMD_SLEEP_ACTION:-unspecified-sleep-mode}}

if [ ! -e /home/deck/.force-ath11k-reload ]
then
    exit 0
fi

case ${1:-} in
  pre)
      logger "system-sleep: Unloading '${modlist[*]}' before $op"
      (modprobe -r "${modlist[@]}" 2>&1 || :) | logger
    ;;
  post)
    for mod in "${modlist[@]}"
    do
      logger "system-sleep: Reloading '$mod' after $op"
      (modprobe "$mod" 2>&1 || :) | logger
    done
    ;;
  *)
    logger "system-sleep: Unknown suspend mode: '${1:-}'"
    ;;
esac
