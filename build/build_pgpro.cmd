SET ARCH=X64
rem SET CONFIG=Debug
SET SDK=MSVC2013
SET PG_MAJOR_VERSION=11
SET PG_PATCH_VERSION=2
rem SET PRODUCT_NAME=PostgresPro
SET PRODUCT_NAME=PostgresProEnterprise
SET NOLOAD_SRC=1
rem SET PGURL=http://repo.l.postgrespro.ru/pgproee-10-beta/src/postgrespro-enterprise-10.3.2.tar.bz2
call run.cmd %1
