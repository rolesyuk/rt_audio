#!/bin/bash

# Top USB 3.0
IRQ_NO=$(awk -F ':' '/6297600/ {print $1}' /proc/interrupts | tr -d '[:space:]')

IRQ_PID=$(ps -eLo pid,cmd | grep "irq/${IRQ_NO}" | awk '/xhci/ {print $1}')
chrt -f -p 90 ${IRQ_PID}
