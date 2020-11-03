#!/bin/bash

/usr/pgsql-12/bin/psql -U postgres -d postgres \
    -c "select distinct wait_event, wait_event_type, count(*) from pg_stat_activity group by wait_event, wait_event_type;"
