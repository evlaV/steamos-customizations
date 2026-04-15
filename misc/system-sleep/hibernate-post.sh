#!/bin/bash
# Copyright © 2025 Valve Corporation.

# This script is designed to be invoked by systemd-sleep.
# It expects 2 args: <pre|post> and the requested sleep mode

set -eu

declare op=${2:-${SYSTEMD_SLEEP_ACTION:-unspecified-sleep-mode}}

case ${1:-} in
  post)
    case "$op" in
      hibernate)
        logger "system-sleep: Running hibernate cleanup after $op"
        /usr/lib/steamos/hibernate-swap-helper.sh cleanup 2>&1 | logger
        logger "system-sleep: Reset boot counter after $op"
        /usr/bin/steamos-bootconf --set boot-attempts 0 2>&1 | logger
        ;;
    esac
    ;;
esac
