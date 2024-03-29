REM ----------------------------------------------------------------------------
REM Assume, you have your PostgreSQL and PgAdmin3 build in %BUILD_DIR%\distr_X.._9.x...
REM For PostgreSQL you have 'postgresql' directory and
REM for PgAdmin3 you have 'pgadmin' directory
REM ----------------------------------------------------------------------------

REM Set NSIS PostgreSQL Variables
SET DEFAULT_PORT=5432
SET DEFAULT_USER=postgres

SET PRODUCT_PUBLISHER="Postgres Professional Russia"
SET COMPANY_NAME=Postgres Professional
SET PRODUCT_WEB_SITE="http://postgrespro.ru"

IF %ARCH% == X86 (
   SET BITS=32bit
) else (
  SET BITS=64bit
)

SET PG_INS_SUFFIX=%BITS%_Setup.exe

IF %ONE_C% == YES (
  SET PRODUCT_NAME=PostgreSQL 1C
  IF %BITS%==32bit SET PG_DEF_SERVICEID=postgresql-1c-%PG_MAJOR_VERSION%-%BITS%
  IF %BITS%==64bit SET PG_DEF_SERVICEID=postgresql-1c-%PG_MAJOR_VERSION%
  SET WITH_1C="TRUE"
) ELSE (
  SET PRODUCT_NAME=PostgreSQL
  IF %BITS%==32bit SET PG_DEF_SERVICEID=postgresql-%PG_MAJOR_VERSION%-%BITS%
  IF %BITS%==64bit SET PG_DEF_SERVICEID=postgresql-%PG_MAJOR_VERSION%
  SET WITH_1C="FALSE"
)

SET OLD_PRODUCT_DIR_REGKEY=SOFTWARE\%COMPANY_NAME%\%ARCH%\%PG_MAJOR_VERSION%
SET OLD_PREV_PRODUCT_DIR_REGKEY=SOFTWARE\%COMPANY_NAME%\%ARCH%\%PG_PREV_MAJOR_VERSION%

SET PG_OLD_REG_KEY="%OLD_PRODUCT_DIR_REGKEY%\Installations\postgresql-%PG_MAJOR_VERSION%"
SET PG_OLD_REG_SERVICE_KEY="%OLD_PRODUCT_DIR_REGKEY%\Services\postgresql-%PG_MAJOR_VERSION%"
SET PG_OLD_PREV_REG_KEY="%OLD_PREV_PRODUCT_DIR_REGKEY%\Installations\postgresql-%PG_PREV_MAJOR_VERSION%"
SET PG_OLD_PREV_REG_SERVICE_KEY="%OLD_PREV_PRODUCT_DIR_REGKEY%\Services\postgresql-%PG_PREV_MAJOR_VERSION%"


SET PRODUCT_DIR_REGKEY=SOFTWARE\%COMPANY_NAME%\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%
SET PG_REG_KEY=%PRODUCT_DIR_REGKEY%\Installations\%PG_DEF_SERVICEID%
SET PG_REG_SERVICE_KEY=%PRODUCT_DIR_REGKEY%\Services\%PG_DEF_SERVICEID%

SET PRODUCT_VERSION="%PG_MAJOR_VERSION% (%BITS%)"

SET PG_DEF_PORT="%DEFAULT_PORT%"
SET PG_DEF_SUPERUSER="%DEFAULT_USER%"
SET PG_DEF_SERVICEACCOUNT="NT AUTHORITY\NetworkService"
SET PG_DEF_BRANDING="%PRODUCT_NAME% %PG_MAJOR_VERSION% (%BITS%)"
rem SET PG_INS_SOURCE_DIR="%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\postgresql\*.*"
SET PG_INS_SOURCE_DIR="%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\postgresql"

SET NSIS_RES_DIR=%~dp0
SET NSIS_RES_DIR=%NSIS_RES_DIR:~0,-1%
SET NSIS_RES_DIR=%NSIS_RES_DIR%\..\..\nsis

REM PostgreSQL Section
>%NSIS_RES_DIR%\postgres.def.nsh ECHO !addplugindir "%NSIS_RES_DIR%\Plugins"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_NAME "%PRODUCT_NAME%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_VERSION %PRODUCT_VERSION%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_PUBLISHER %PRODUCT_PUBLISHER%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_WEB_SITE %PRODUCT_WEB_SITE%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_DIR_REGKEY "%PRODUCT_DIR_REGKEY%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_REG_KEY "%PG_REG_KEY%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_REG_SERVICE_KEY "%PG_REG_SERVICE_KEY%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_PORT %PG_DEF_PORT%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_SUPERUSER %PG_DEF_SUPERUSER%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_SERVICEACCOUNT %PG_DEF_SERVICEACCOUNT%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_SERVICEID %PG_DEF_SERVICEID%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_VERSION %PG_DEF_VERSION%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_MAJOR_VERSION %PG_MAJOR_VERSION%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_BRANDING %PG_DEF_BRANDING%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_INS_SUFFIX %PG_INS_SUFFIX%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_INS_SOURCE_DIR %PG_INS_SOURCE_DIR%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define REDIST_YEAR %REDIST_YEAR%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define WITH_1C %WITH_1C%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define BUILD_DIR %BUILD_DIR%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define SDK %SDK%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define HAVE_PGSQL_DOC %HAVE_PGSQL_DOC%


>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_OLD_REG_KEY %PG_OLD_REG_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_OLD_REG_SERVICE_KEY %PG_OLD_REG_SERVICE_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_OLD_PREV_REG_KEY %PG_OLD_PREV_REG_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_OLD_PREV_REG_SERVICE_KEY %PG_OLD_PREV_REG_SERVICE_KEY%


IF "%ARCH%" == "X64" (
  >>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_64bit
)

>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define  myLicenseFile_ru "license.txt"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define  myLicenseFile_en "license.txt"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_NAME_SHORT "PostgreSQL"


CD %NSIS_RES_DIR% || GOTO :ERROR

rem Genarate file lists
rem Remove old filelists first
rm -f *_list.nsi
rem tune pattern lists to major version and product

IF %PG_MAJOR_VERSION% LEQ 13 (
    sed "s/pg_amcheck//" client.files > client-14.files
    mv client-14.files client.files
)

IF "%PG_MAJOR_VERSION%" == "9.6" (
	sed "s/wal/xlog/" server.files > allserver.files
	sed  "s/wal/xlog/" client.files > allclient.files
	echo ./bin/createlang.* >> allclient.files
	echo ./bin/droplang.* >> allclient.files
) ELSE (
    cat server.files > allserver.files
	type client.files > allclient.files
)
IF %PG_MAJOR_VERSION% GEQ 12 (
    sed "s/pg_verify_checksums/pg_checksums/" allserver.files > allserver-12.files
    mv allserver-12.files allserver.files
)

rem expand pattern lists to actual file lists
%PYTHON64_PATH%/python %ROOT%/build/helpers/genlists.py %PG_INS_SOURCE_DIR% allclient.files devel.files plperl.files plpython2.files plpython3.files unneeded.files allserver.files || GOTO :ERROR

makensis postgresql.nsi || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
REM PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
REM PAUSE
