#!/bin/bash
function script_lock {
    # Check to see if we're already running
    if [ ! -e "${LOCK_FILE}" ]
    then
        trap "rm -f ${LOCK_FILE}; exit" "${SIGNALS[@]}"
        touch "${LOCK_FILE}"
        sync
    else
    echo "${0} already running."
    exit 1
    fi
}
# General clean up function
function cleanup {
    rm -f "${LOCK_FILE}"
    trap - INT TERM EXIT
    set +o nounset
    set +o errexit
    sync
}
# Error logging
function elog {
    echo "$(date '+%b %d %T') ${$} ${LINENO}: ${1}" >> "${LOG_FILE}"
    sync
}
