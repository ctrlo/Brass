#!/bin/bash

echo Using database brass. Please enter the root password of the mysql database:
read PASSWORD

dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' Brass::Schema 'dbi:mysql:dbname=brass' root $PASSWORD

