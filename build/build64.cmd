SET ARCH=X64
SET SDK=MSVC2013
SET PG_MAJOR_VERSION=12
SET PG_PATCH_VERSION=2.1
SET PRODUCT_NAME=PostgresProEnterprise
rem SET PRODUCT_NAME=PostgreSQL 1C
rem SET ONE_C=YES
rem SET PGURL=http://repo.postgrespro.ru/1c-10-beta/src/postgrespro-1c-10.3.tar.bz2
rem SET GIT_PATH=https://git.postgrespro.ru/pgpro-dev/postgrespro.git
rem GIT_BRANCH=PGPROEE12_DEV
SET PERL5LIB=.
SET MSBFLAGS=/m
SET WITHTAPTESTS=1
SET NOLOAD_SRC=
rem SET ISDEV=0
rem SET BUILD_TYPE=dev
call run.cmd %1
