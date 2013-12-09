#!/usr/bin/env bash

std_datetime=`date "+%Y-%m-%d %H:%M:%S"`
log_dir=/var/log/license_auto
pg_dump license_auto > "${log_dir}/license_auto.${std_datetime}.sql"
echo "${std_datetime} PostgreSQL backup ok." >> ${log_dir}/license_auto.log
