#!/bin/bash

################################################################################
# source the ansible and pg_env commands
################################################################################
set -u
set -e

################################################################################
# Postgres environment variables
################################################################################

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "${SCRIPT}")


source ${SCRIPT_PATH}/../edb_env.sh
source ${SCRIPT_PATH}/edb_funcs.sh

set +e 
################################################################################
# create pg_index
################################################################################

plog "Creating PGDATA, PGWAL, PGINDEXES directories"
${PGSUDO} mkdir -p ${PGDATA}
${PGSUDO} mkdir -p ${PGWAL}
${PGSUDO} mkdir -p ${PGINDEXES}

${PGSUDO} chmod 700 ${PGWAL}
${PGSUDO} chmod 700 ${PGDATA}
${PGSUDO} chmod 700 ${PGINDEXES}


################################################################################
# Update the block devices for 8kB writes
################################################################################

plog "Chaning block devices"
sudo blockdev --setra 8192 ${BLCK_DEVICE_PGWAL}
sudo blockdev --setra 8192 ${BLCK_DEVICE_PGDATA}
sudo blockdev --setra 8192 ${BLCK_DEVICE_PGINDEXES}

################################################################################
# Update scheduler
################################################################################

plog "Updating the scheduler"
sudo bash -c "echo deadline > ${SCHEDULE_PGWAL}"
sudo bash -c "echo deadline > ${SCHEDULE_PGDATA}"
sudo bash -c "echo deadline > ${SCHEDULE_PGINDEXES}"

################################################################################
# Update disable transparent huge pages
################################################################################

plog "Disabling transparent huge pages"
sudo bash -c "echo never > /sys/kernel/mm/transparent_hugepage/defrag"
sudo bash -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
sudo bash -c "echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag"
sudo grubby --update-kernel=ALL --args='transparent_hugepage=never'

################################################################################
# update systemctl 
################################################################################

plog "Changing system control parameters"
sudo sysctl -w vm.nr_hugepages=52600
sudo sysctl -w vm.swappiness=1
sudo sysctl -w vm.max_map_count=3112960
sudo sysctl -w net.core.somaxconn=1024
