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
# set the os configuration
################################################################################

${SCRIPT_PATH}/lib/os_config.sh

################################################################################
# initialize the database and set the server parameters
################################################################################

initialize_db
start_stop_pg start

plog "Setting the parameters"
cat ${LIBSQL}/pg_parameters.sql \
  | ${PGSUDO} ${PSQL} --user=${PGUSER} \
                      --port=${PGPORT} \
                      --host=${PGHOST} \
                      --dbname=${PGDATABASE}

plog "Creating pg_indexes tablespace"
${PGSUDO} ${PSQL} --command="CREATE TABLESPACE pgindexes LOCATION '${PGINDEXES}'" \
                  --user=${PGUSER} \
                  --port=${PGPORT} \
                  --host=${PGHOST} \
                  --dbname=${PGDATABASE}

plog "creating pg_prewarm extension in ${PGDATABASE}"
${PGSUDO} ${PSQL} --command="CREATE EXTENSION pg_prewarm;" \
                  --user=${PGUSER} \
                  --port=${PGPORT} \
                  --host=${PGHOST} \
                  --dbname=${PGDATABASE}

plog "Stop and start Postgres for changed parameters to take effect"
start_stop_pg stop
start_stop_pg start

build_pgbench_db

${PGSUDO} ${PSQL} --command="CHECKPOINT;" \
                  --username=${PGUSER} \
                  --port=${PGPORT} \
                  --host=${PGHOST} \
                  --dbname=${PGDATABASE}

################################################################################
# stop the database before backup and take the backup
################################################################################

plog "stop Postgres before backup"
start_stop_pg stop

${PGSUDO} rsync -ahW --no-compress ${PGDATA}/ ${PGDATA_BCKUP} &
${PGSUDO} rsync -ahW --no-compress ${PGINDEXES}/ ${PGINDEXES_BCKUP} &
${PGSUDO} rsync -ahW --no-compress ${PGWAL}/ ${PGWAL_BCKUP} &
wait
