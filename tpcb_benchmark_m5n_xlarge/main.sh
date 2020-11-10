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
${SCRIPT_PATH}/edb_server.sh
${SCRIPT_PATH}/pgbench_runs.sh
