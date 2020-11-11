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
# function set the parameters and restart
################################################################################

function update_pg_parameters()
{
    plog "Setting the parameters"
    start_stop_pg start
    cat ${LIBSQL}/pg_parameters.sql \
    | ${PGSUDO} ${PSQL} --user=${PGUSER} \
                        --port=${PGPORT} \
                        --host=${PGHOST} \
                        --dbname=${PGDATABASE}
    
    plog "Stop Postgres after parameter changes"
    start_stop_pg stop
    plog "Start Postgres"
    start_stop_pg start
}

################################################################################
# function restore the database from backup
################################################################################

function restore_pg()
{
    plog "Stopping Postgres"
    start_stop_pg stop
    # clear the cache before proceed.
    plog "Clearing the OS cache"
    sudo sync 
    sudo bash -c 'echo 3 > /proc/sys/vm/drop_caches'

    plog "Cleanup the Postgres database and restore from backup."
    ${PGSUDO} rm -rf ${PGDATA} &
    ${PGSUDO} rm -rf ${PGWAL} &
    ${PGSUDO} rm -rf ${PGINDEXES} &
    wait

    ${PGSUDO} rsync -ahW \
                    --no-compress \
                    ${PGDATA_BCKUP}/ ${PGDATA} &
    ${PGSUDO} rsync -ahW \
                    --no-compress \
                    --progress \
                    ${PGINDEXES_BCKUP}/ ${PGINDEXES} &
    ${PGSUDO} rsync -ahW \
                    --no-compress \
                    ${PGWAL_BCKUP}/ ${PGWAL} &
    wait
}

################################################################################
# function restore the database from backup
################################################################################

function pgbench_steps()
{
  
    typeset -r F_CONNECTIONS="$1"
    typeset -r F_THREADS="$1"
    typeset -r F_LOGFILE="$3"

    plog "Starting Postgres if its not started yet"
    start_stop_pg start
    plog "Peform pg_prewarm"
    cat ${LIBSQL}/pgbench_prewarm.sql \
     | ${PGSUDO} ${PSQL} --user=${PGUSER} \
                         --port=${PGPORT} \
                         --host=${PGHOST} \
                         --dbname=${PGDATABASE}

     plog "Perform checkpoint"
     ${PGSUDO} ${PSQL} --command="CHECKPOINT;" \
                       --username=${PGUSER} \
                       --port=${PGPORT} \
                       --host=${PGHOST} \
                       --dbname=${PGDATABASE}

     plog "Perform pgbench"
     ${PGBIN}/pgbench --client=${F_CONNECTIONS} \
                      --jobs=${F_THREADS} \
                      --time=${DURATION} \
                      --protocol=prepared \
                      --username=${PGUSER} \
                      --port=${PGPORT} \
                      --host=${PGHOST} \
                      ${PGDATABASE} >${F_LOGFILE}

}

################################################################################
# pgbech test
################################################################################

update_pg_parameters

for ((run = 1 ; run <= ${NO_OF_RUNS} ; run++))
do
    # print the run number
    plog "RUN => ${run}"

    # create run the director
    plog "Creating log dirtectory for run"
    mkdir -p ${LOGDIR}/${run}

    # start the database if its not running
    plog "Starting Postgres if its not started yet"
    start_stop_pg start

    RUN_SUMMARY="${LOGDIR}/${run}/summary_tps.txt"

    for threads in ${PGBENCH_CONNECTIONS_LIST}
    do
        RUN_LOGFILE=${LOGDIR}/${run}/${threads}_conn.log

        plog "Running pgbench for ${threads} number of connections"
        pgbench_steps "${threads}" "${threads}" "${RUN_LOGFILE}"
       
        # backup the postgresql log file
        sudo mv ${PGDATA}/log/postgresql.log ${LOGDIR}/${run}
        sudo chown ${USER}:${USER} ${LOGDIR}/${run}/postgresql_${threads}.log

        restore_pg
        update_pg_parameters
    done
    # consolidate the run tps with connections
    echo "connections,RUN: ${run}(tps)" >${RUN_SUMMARY}
    for file in $(ls -1 ${LOGDIR}/${run}/*_conn.log|grep -v postgresql.log)
    do
        echo "$(basename ${file}|cut -d"_" -f1),$(cat ${file} \
                     | grep "including connections" \
                     |awk '{print $3}')" >>${RUN_SUMMARY}
    done
    cat ${RUN_SUMMARY} | sort -nu \
                      > ${RUN_SUMMARY}_sorted
    rm ${RUN_SUMMARY}
    mv ${RUN_SUMMARY}_sorted ${RUN_SUMMARY}
done
paste -d"," ${LOGDIR}/1/summary_tps.txt \
            ${LOGDIR}/2/summary_tps.txt \
            ${LOGDIR}/3/summary_tps.txt \
    |awk -F"," '{print $1","$2","$4","$6}' >${LOGDIR}/consolidated_tps.txt
