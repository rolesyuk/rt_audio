#!/bin/bash

IRQ_NO=$(awk -F ':' '/1579008/ {print $1}' /proc/interrupts | tr -d '[:space:]')
IRQ_PID=$(ps -eLo pid,cmd | grep "irq/${IRQ_NO}" | awk '/xhci/ {print $1}')
chrt -f -p 90 ${IRQ_PID}

find /sys -name scaling_governor 2>/dev/null | while read GOVERNOR; do
	echo performance > $GOVERNOR
done

echo performance > /sys/module/pcie_aspm/parameters/policy

echo 1 > /sys/devices/system/cpu/cpufreq/boost
echo 0 > /sys/devices/system/cpu/cpufreq/boost
