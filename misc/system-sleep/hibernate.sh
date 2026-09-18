#!/bin/bash
# Copyright © 2025 Valve Corporation.

# This script is designed to be invoked by systemd-sleep.
# It expects 2 args: <pre|post> and the requested sleep mode

set -eu

declare op=${2:-unspecified-sleep-mode}
declare action=${SYSTEMD_SLEEP_ACTION:-unspecified-sleep-action}

# We only handle hibernate and the hibernate part of suspend-then-hibernate
[ "$op" != "hibernate" ] && [ "$action" != "hibernate" ] && exit

case ${1:-} in
  pre)
        logger "system-sleep: Creating swap before hibernate ($op)"
        /usr/lib/holo/hibernate-swap-helper.sh create 2>&1 | logger
    ;;
  post)
        logger "system-sleep: Running hibernate cleanup after hibernate ($op)"
        /usr/lib/holo/hibernate-swap-helper.sh cleanup 2>&1 | logger
        logger "system-sleep: Reset boot counter after hibernate ($op)"
        /usr/bin/holo-bootconf --set boot-attempts 0 2>&1 | logger
    ;;
esac
