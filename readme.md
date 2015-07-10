PostrgreSQL install script for NSIS
Written by Victor Spirin for Postgres Professional, Postgrespro.com

Main file of project is postgres_x86.nsi

Was use plugins: AccessControl, UserMgr

AddToPath plugin included in this project in AddToPath directory

Postgresql binaries file must be present in subdirectories, defined in PG_INS_SOURCE_DIR (see postgres64.nsh, postgres64a.nsh, postgres32.nsh, postgres32a.nsh for postgresql install options).
