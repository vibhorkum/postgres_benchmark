#!/bin/bash

################################################################################
# source the ansible and pg_env commands
################################################################################
set -u
set -e

################################################################################
# function: print messages with process id
################################################################################
function plog()
{
       echo "PID: $$ [RUNTIME: $(date +'%m-%d-%y %H:%M:%S')]: $*" >&2
}


################################################################################
# function: initialize the database
################################################################################

function initialize_db()
{
    plog "Initializing the cluster"
    ${PGSUDO} ${INITDB} --pgdata=${PGDATA} \
                        --waldir=${PGWAL} \
                        --wal-segsize=128 \
                        --encoding=UTF-8 >${LOGDIR}/initdb.log 2>&1
    ${PGSUDO} mkdir -p ${PGDATA}/log
}

################################################################################
# function: set server parameters
################################################################################

function set_server_parameter()
{
  typeset -r F_PARAMETER="$1"
  typeset -r F_VALUE="$2"
  typeset -r F_SQL="ALTER SYSTEM SET ${F_PARAMETER} TO ${F_VALUE};"

  plog "Setting parameter ${F_PARAMETER} value ${F_VALUE}"
  ${PGSUDO} ${PSQL} -c "${F_SQL}" |grep -v "could not change directory to"
}

################################################################################
# function: build database of specific size
################################################################################

function build_pgbench_db()
{
    typeset -r F_SCALE_FACTOR="$( echo 0.0781*${DBSIZE_GB}*1024 - 0.5 |bc )"

    plog "Building pgbench database using ${DBSIZE_GB}"
    ${PGSUDO} ${PGBIN}/pgbench --initialize \
                               --scale=${F_SCALE_FACTOR} \
                               --index-tablespace=pgindexes \
                               --user=${PGUSER} \
                               --port=${PGPORT} \
                               ${PGDATABASE} >>${LOGDIR}/build_db.log 2>&1
}

################################################################################
# function: start/stop pg
################################################################################

function start_stop_pg()
{
     typeset -r F_ACTION="$1"

     typeset STATUS_CODE
     typeset LOGFILE=${LOGDIR}/pg_ctl.log

     set +e

     ${PGSUDO} ${PGCTL} --pgdata=${PGDATA} status \
                        --silent >>${LOGFILE} 2>&1
     STATUS_CODE=$?

     if [[ "${F_ACTION}" = "stop" && "${STATUS_CODE}" != "3" ]]
     then
         ${PGSUDO} ${PGCTL} --pgdata=${PGDATA} stop \
                            --wait \
                            --silent \
                            --log=${PGDATA}/log/start_stop.log  \
                            >>${LOGFILE} 2>&1

     elif [[ "${F_ACTION}" = "start" && "${STATUS_CODE}" != "0" ]]
     then
         ${PGSUDO} ${PGCTL} --pgdata=${PGDATA} start \
                            --wait \
                            --silent \
                            --log=${PGDATA}/log/start_stop.log \
                            >> ${LOGFILE} 2>&1
     fi
     set -e
 }
