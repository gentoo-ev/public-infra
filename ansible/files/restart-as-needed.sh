#! /usr/bin/env bash
# Copyright (c) 2020 Sebastian Pipping <sebastian@pipping.org>
# Distributed under the terms of the MIT license

set -e
set -u

# Does a more recent kernel ask for a reboot?
tracer_exit_code=0
tracer --hooks-only || tracer_exit_code=$?
if [[ ${tracer_exit_code} -eq 104 ]]; then
    reboot
    exit 0
fi
unset tracer_exit_code


tracer_verbose_output="$(tracer -v -e || true)"

# Service auditd is configured to prohibit manual restarts
# so we reboot the whole machine, not just auditd.
if grep -q 'systemctl restart auditd$' <<<"${tracer_verbose_output}"; then
    reboot
    exit 0
fi

# Restart all out-of-date daemons.
# We're reversing order so that firewalld is restarted
# before docker because the Internet suggests this way around
# may cause less trouble
grep -o 'systemctl restart [^ ]\+$' <<<"${tracer_verbose_output}" \
    | sort -u -r \
    | grep -v ' dnf-automatic$' \
    | xargs -n 3 -r -t env
