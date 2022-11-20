#!/bin/bash

sp=$(cat ~/.ssh/script_password)
sudo apt update

# check if postgresql already exits. If it does, nothing happens. If it doesn't, the installation code runs.
function check() {
if [[ $( dpkg-query -l postgresql >> /dev/null 2>&1 )$? -eq 0 ]]
then
:
else
( sudo apt install postgresql postgresql-contrib -y )
fi
}
check

# checks if postgresql is active. If it isn't, it tries to start it and enable it to start at boot
function activate() {
if [[ $( sudo systemctl status postgresql >> /dev/null 2>&1 )$? -eq 0 ]]
then
:
else
( sudo systemctl start postgresql >> /dev/null 2>&1 )
( sudo systemctl enable postgresql >> /dev/null 2>&1 )
fi
}
activate

# checks if postgresql user account has a passwd, then creates a passwd if necessary
function password() {
if [[ $( sudo passwd --status postgres | awk '{print $2}' ) != 'P' ]]
then
( echo postgres:$sp | sudo chpasswd )
else
:
fi
}
password

# create a role and a database
function createROLE() {
addRole=$( sudo -u postgres psql -c "create role altschool createdb createrole login password '$(cat ~/.ssh/script_password )'" >> /dev/null 2>&1 )$?
if [[ $addRole -eq 1 ]]
then
:
else
( sudo -u postgres psql -c "create role altschool createdb createrole login password '$(cat ~/.ssh/script_password )'" >> /dev/null 2>&1 )
fi
}
createROLE

function createDB() {
createDb=$( sudo -u postgres createdb -O altschool exam >> /dev/null 2>&1 )$?
if [[ $createDb -eq 1 ]]
then
:
else
( sudo -u postgres createdb -O altschool exam >> /dev/null 2>&1 )
fi
}
createDB

function setUp() {
sudo echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf
sudo echo host all all 0.0.0.0/0 md5 >> /etc/postgresql/*/main/pg_hba.conf
systemctl restart postgresql
}
setUp
