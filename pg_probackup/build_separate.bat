SET PGDIRSRC=Z:\extension-packaging\pg_probackup\windows\postgresql
SET PGDIR=Z:\inst\
SET PGDIRSRC=Z:\pgwininstall\builddir\postgresql\postgresql-11.2.1
SET PGDIR=Z:\Program Files\PostgresProEnterprise\11
SET APPVERSION=2.1.1
rem SET PRODUCT_DIR_REGKEY=SOFTWARE\PostgresPro\X64\PostgresProEnterprise\11\Installations\postgresql-11
SET PG_REG_KEY=SOFTWARE\PostgresPro\X64\PostgresProEnterprise\11\Installations\postgresql-11
SET PG_DEF_BRANDING=PostgresPro Enterprise 11
SET PRODUCT_NAME=PostgresProEnterprise
SET BITS=64bit
SET PGVER=11.1.1

call build_pro_backup.bat || GOTO :ERROR

goto :DONE
:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%
:DONE
ECHO Done.
