#!/bin/sh

# ------------------------------------------------------------------------------
#
# ESXi - Network RX drops Script
#
# Version:  1.2
# Date:     July 2018
# Author:   Vladimir Akhmarov
#
# Description:
#   This script prints statistics for rx queue drops that may be observed in
#   high vCPU/pCPU placement scenario
#
#   For example:
#   ./esxrxdrops.sh | more
#
# ------------------------------------------------------------------------------

IFS=$'\n'

for vm in $(net-stats -l | grep -v 'MAC\|vmnic\|vmk' | sort -k6); do
    SW_NAME=$(echo $vm | awk '{print $4}')
    VM_NAME=$(echo $vm | awk '{print $6}')
    VM_PORT=$(echo $vm | awk '{print $1}')

    # Get droppedRx counter for current VM nic
    RXDROPS=$(vsish -e get /net/portsets/$SW_NAME/ports/$VM_PORT/clientStats | grep -i 'droppedRx:' | awk -F ":" '{print $2}')

    if [ "$RXDROPS" -gt "0" ]; then
        echo 'Virtual machine, nic:'
        echo "   $VM_NAME"

        echo 'Virtual machine clientStats, non-zero dropped:'
        vsish -e get /net/portsets/$SW_NAME/ports/$VM_PORT/clientStats | grep -i 'dropped' | grep -v ':0'

        echo 'Virtual machine rxSummary, non-zero buffer full:'
        vsish -e get /net/portsets/$SW_NAME/ports/$VM_PORT/vmxnet3/rxSummary | grep -i 'full\|out' | grep -v ':0'

        for queue in $(vsish -e ls /net/portsets/$SW_NAME/ports/$VM_PORT/vmxnet3/rxqueues/); do
            Q_NUM=$(echo $queue | sed 's/.$//')

            echo "Virtual machine queue $Q_NUM:"
            vsish -e get /net/portsets/$SW_NAME/ports/$VM_PORT/vmxnet3/rxqueues/$Q_NUM/status | grep -i 'ring #'
        done

        echo ''
    fi
done
