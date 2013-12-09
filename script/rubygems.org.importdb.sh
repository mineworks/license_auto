#!/usr/bin/env bash


su postgres
cd ~
# TODO: write a Ruby spider to auto
wget https://s3-us-west-2.amazonaws.com/rubygems-dumps/production/public_postgresql/2015.09.07.21.21.02/public_postgresql.tar

tar -xvf public_postgresql.tar
gunzip public_postgresql/databases/PostgreSQL.sql.gz

rm -rf public_postgresql*

sql_filename=public_postgresql/databases/PostgreSQL.sql

dbname=gemData
dropdb $dbname
createdb $dbname
psql $dbname -c 'create extension hstore;'

psql $dbname < $sql_filename
echo 'OK'
