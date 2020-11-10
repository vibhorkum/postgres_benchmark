#!/bin/bash

################################################################################
# source the ansible and pg_env commands
################################################################################
set -u
set -e

################################################################################
# Postgres environment variables
################################################################################

PGBIN=/usr/pgsql-12/bin
PGUSER="postgres"
PGOWNER="postgres"
PGPORT=5432
PGDATABASE=postgres
PGHOST=/tmp

PGCTL=${PGBIN}/pg_ctl
INITDB=${PGBIN}/initdb
PSQL="${PGBIN}/psql -qAt "

PGDATA=/pg_data/data
PGWAL=/pg_wal/wal
PGINDEXES=/pg_indexes/indexes


export PGUSER PGPORT PGDATABASE PGHOST PGDATA PSQL
export PGWAL PGINDEXES INITDB PGBIN PGCTL

################################################################################
# set the libdir
################################################################################

ENV_PATH=$(readlink -f "$0")
ENV_DIR=$(dirname "${ENV_PATH}")

LIBDIR=${ENV_DIR}/lib
LIBSQL=${ENV_DIR}/lib_sql
LOGDIR=${ENV_DIR}/log

PGSUDO="sudo -Hiu ${PGOWNER}"

export LIBDIR LIBSQL PGSUDO

################################################################################
# pgbench specific variables
################################################################################

DBSIZE_GB=200
NO_OF_RUNS=3
PGBENCH_CONNECTIONS_LIST="128 1 256 512 16 550 64 32 600"
DURATION=600

export DBSIZE_GB NO_OF_RUNS PGBENCH_CONNECTIONS_LIST
export DURATION LOGDIR

################################################################################
# Postgres postgres_backup
################################################################################

PGDATA_BCKUP=/pg_data/data.backup
PGWAL_BCKUP=/pg_wal/wal.backup
PGINDEXES_BCKUP=/pg_indexes/indexes.backup

export PGDATA_BCKUP PGWAL_BCKUP PGINDEXES_BCKUP

################################################################################
# BLOCK devices of PGDATA/PGWAL/PGINDEXES
################################################################################
PG_WAL_MOUNT="/pg_wal"
PG_DATA_MOUNT="/pg_data"
PG_INDEXES_MOUNT="/pg_indexes"
BLCK_DEVICE_PGWAL="/dev/$(lsblk |grep ${PG_WAL_MOUNT}|awk '{print $1}')"
BLCK_DEVICE_PGDATA="/dev/$(lsblk |grep ${PG_DATA_MOUNT}|awk '{print $1}')"
BLCK_DEVICE_PGINDEXES="/dev/$(lsblk |grep ${PG_INDEXES_MOUNT}|awk '{print $1}')"

################################################################################
# scheduler for PGDATA/PGWAL/PGINDEXES
################################################################################

SYS_BLCK_BASE=/sys/block
SCHEDULE_PGWAL=/sys/block/$(lsblk |grep ${PG_WAL_MOUNT}|awk '{print $1}')/queue/scheduler
SCHEDULE_PGDATA=/sys/block/$(lsblk |grep ${PG_DATA_MOUNT}|awk '{print $1}')/queue/scheduler
SCHEDULE_PGINDEXES=/sys/block/$(lsblk |grep ${PG_INDEXES_MOUNT}|awk '{print $1}')/queue/scheduler
