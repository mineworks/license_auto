#!/usr/bin/env bash

su postgres
wget https://s3-us-west-2.amazonaws.com/rubygems-dumps/production/public_postgresql/2015.09.07.21.21.02/public_postgresql.tar

# TODO: tar xvzf public_postgresql.tar
sql_filename=PostgreSQL.sql

dbname=gemData
dropdb $dbname
createdb $dbname
psql $dbname -c 'create extension hstore;'
psql $dbname < $sql_filepath
