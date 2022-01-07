#!/bin/bash

PROGRAM="Archetype Nolly"
PRIORITY="65"

THREAD_PID=$(ps H -eo tid,class,comm --sort=+%cpu | grep "${PROGRAM}" | grep -v "FF" | tail -n1 | awk '{print $1}')

chrt -ff -p "${PRIORITY}" "${THREAD_PID}"
