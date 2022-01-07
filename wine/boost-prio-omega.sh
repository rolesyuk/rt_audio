#!/bin/bash

PROGRAM="OMEGA Ampworks"
PRIORITY="65"

THREAD_PIDS=$(ps H -eo tid,class,comm --sort=+%cpu | grep "${PROGRAM}" | grep -v "FF" | awk '{print $1}')

echo ${THREAD_PIDS}
for THREAD_PID in ${THREAD_PIDS}; do
	chrt -ff -p "${PRIORITY}" "${THREAD_PID}"
done
