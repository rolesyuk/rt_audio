#!/bin/bash

echo 0 > /sys/devices/system/cpu/cpufreq/boost

CSET_USER="roman"
cset set --cpu=0-1 --set=kernel
cset set --cpu=2-11 --set=user
cset set --cpu=12-15 --set=neuraldsp
cset proc --kthread --fromset=root --toset=kernel
cset proc --move --fromset=root --toset=user
chown ${CSET_USER}:${CSET_USER} -R /sys/fs/cgroup/cpuset/neuraldsp

IRQ_NO=$(awk -F ':' '/1579008/ {print $1}' /proc/interrupts | tr -d '[:space:]')
IRQ_PID=$(ps -eLo pid,cmd | grep "irq/${IRQ_NO}" | awk '/xhci/ {print $1}')
chrt -f -p 90 ${IRQ_PID}

chown roman:roman /dev/cpu_dma_latency
