#!/usr/bin/env bash

#su postgres

dbname='license_auto'
username='postgres'
pg_schema='public'
opt=" -U ${username} --schema=${pg_schema} --schema-only"
pg_dump $opt $dbname > $dbname.sql
