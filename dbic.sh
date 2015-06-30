#!/bin/bash

echo Using database brass. Please enter the root password of the mysql database:
read PASSWORD

#dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' Brass::Schema 'dbi:mysql:dbname=brass' root $PASSWORD
#dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' Brass::DocSchema 'dbi:mysql:dbname=docdb:docs.ctrlo.com;mysql_ssl=1;mysql_ssl_client_key=/etc/mysql/ctrlo-certs/client-key.pem;mysql_ssl_client_cert=/etc/mysql/ctrlo-certs/client-cert.pem;mysql_ssl_ca_file=/etc/mysql/ctrlo-certs/ca-cert.pem;' brass $PASSWORD
dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' Brass::ConfigSchema 'dbi:mysql:dbname=configdb:docs.ctrlo.com;mysql_ssl=1;mysql_ssl_client_key=/etc/mysql/ctrlo-certs/client-key.pem;mysql_ssl_client_cert=/etc/mysql/ctrlo-certs/client-cert.pem;mysql_ssl_ca_file=/etc/mysql/ctrlo-certs/ca-cert.pem;' brass $PASSWORD
#dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' Brass::IssueSchema 'dbi:mysql:dbname=issuedb:docs.ctrlo.com;mysql_ssl=1;mysql_ssl_client_key=/etc/mysql/ctrlo-certs/client-key.pem;mysql_ssl_client_cert=/etc/mysql/ctrlo-certs/client-cert.pem;mysql_ssl_ca_file=/etc/mysql/ctrlo-certs/ca-cert.pem;' brass $PASSWORD

