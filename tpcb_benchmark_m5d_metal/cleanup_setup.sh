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


source ${SCRIPT_PATH}/edb_env.sh
source ${SCRIPT_PATH}/lib/edb_funcs.sh

################################################################################
# Shut down the PG if its running
################################################################################
plog "Stopping Postgres if running"

start_stop_pg stop

################################################################################
# cleanup the directory
################################################################################

plog "Removing the ${PGDATA}"
sudo rm -rf ${PGDATA} &
sudo rm -rf ${PGWAL} &
sudo rm -rf ${PGINDEXES} &
wait

#plog "Restoring data directory"
#${PGSUDO} rsync -ahW --no-compress ${PGDATA_BCKUP}/ ${PGDATA} &
#${PGSUDO} rsync -ahW --no-compress ${PGINDEXES_BCKUP}/ ${PGINDEXES} &
#${PGSUDO} rsync -ahW --no-compress ${PGWAL_BCKUP}/ ${PGWAL} &
#wait

sudo rm -rf ${PGDATA_BCKUP} &
sudo rm -rf ${PGWAL_BCKUP} &
sudo rm -rf ${PGINDEXES_BCKUP} &
wait
################################################################################
# stop the database before backup and take the backup
################################################################################

#plog "stop Postgres before backup"
#start_stop_pg stop

#${PGSUDO} rsync -ahW --no-compress ${PGDATA}/ ${PGDATA_BCKUP} &
#${PGSUDO} rsync -ahW --no-compress ${PGINDEXES}/ ${PGINDEXES_BCKUP} &
#${PGSUDO} rsync -ahW --no-compress ${PGWAL}/ ${PGWAL_BCKUP} &
#wait
