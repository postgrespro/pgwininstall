REM ----------------------------------------------------------------------------
REM Assume, you have your PostgreSQL and PgAdmin3 build in %BUILD_DIR%\distr_X.._9.4...
REM For PostgreSQL you have 'postgresql' directory and
REM for PgAdmin3 you have 'pgadmin' directory
REM ----------------------------------------------------------------------------

REM Set NSIS PostgreSQL Variables
SET DEFAULT_PORT=5432
SET DEFAULT_USER=postgres

SET PRODUCT_PUBLISHER="Postgres Professional Russia"
SET COMPANY_NAME=PostgresPro
SET PRODUCT_WEB_SITE="http://postgrespro.ru"
 
IF %ARCH% == X86 (
   SET BITS=32bit
) else (
  SET BITS=64bit
)

IF "%PRODUCT_NAME%" == "" SET PRODUCT_NAME=PostgresPro

SET PRODUCT_DIR_REGKEY=SOFTWARE\%COMPANY_NAME%\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%
SET OLD_PRODUCT_DIR_REGKEY=SOFTWARE\%COMPANY_NAME%\%ARCH%\%PG_MAJOR_VERSION%

REM Set Service-Id
SET PG_DEF_SERVICEID="postgresql-%ARCH%-%PG_MAJOR_VERSION%"
IF "%PRODUCT_NAME%" == "PostgreSQL" SET PG_DEF_SERVICEID="postgresql-%ARCH%-%PG_MAJOR_VERSION%"
IF "%PRODUCT_NAME%" == "PostgresPro" SET PG_DEF_SERVICEID="postgrespro-%ARCH%-%PG_MAJOR_VERSION%"
IF "%PRODUCT_NAME%" == "PostgresProEnterprise" SET PG_DEF_SERVICEID="postgrespro-enterprise-%ARCH%-%PG_MAJOR_VERSION%"

IF %ONE_C% == YES (
  SET PRODUCT_NAME=PostgresPro 1C
  SET PG_DEF_SERVICEID="postgrespro-1C-${PRODUCT_VERSION}"
  SET PG_INS_SUFFIX="%BITS%_1C_Setup.exe"
  SET PG_REG_KEY="Software\Postgres Professional\${PRODUCT_NAME}\Installations\postgresql-${PRODUCT_VERSION}"
  SET PG_REG_SERVICE_KEY="Software\Postgres Professional\${PRODUCT_NAME}\Services\postgresql-${PRODUCT_VERSION}"
  SET PRODUCT_DIR_REGKEY="Software\Postgres Professional\${PRODUCT_NAME}\${PRODUCT_VERSION}"
  SET PRODUCT_VERSION="%PG_MAJOR_VERSION% (%BITS%)"
) ELSE (
  SET PG_INS_SUFFIX="%BITS%_Setup.exe"
  SET PG_REG_KEY="%PRODUCT_DIR_REGKEY%\Installations\postgresql-%PG_MAJOR_VERSION%"
  SET PG_REG_SERVICE_KEY="%PRODUCT_DIR_REGKEY%\Services\postgresql-%PG_MAJOR_VERSION%"
  SET PG_OLD_REG_KEY="%OLD_PRODUCT_DIR_REGKEY%\Installations\postgresql-%PG_MAJOR_VERSION%"
  SET PG_OLD_REG_SERVICE_KEY="%OLD_PRODUCT_DIR_REGKEY%\Services\postgresql-%PG_MAJOR_VERSION%"
  SET PRODUCT_VERSION="%PG_MAJOR_VERSION% (%BITS%)"
)

SET PG_DEF_PORT="%DEFAULT_PORT%"
SET PG_DEF_SUPERUSER="%DEFAULT_USER%"
SET PG_DEF_SERVICEACCOUNT="NT AUTHORITY\NetworkService"
SET PG_DEF_BRANDING="%PRODUCT_NAME% %PG_MAJOR_VERSION% (%ARCH%)"
SET PG_INS_SOURCE_DIR="%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\postgresql\*.*"

SET NSIS_RES_DIR=%~dp0
SET NSIS_RES_DIR=%NSIS_RES_DIR:~0,-1%
SET NSIS_RES_DIR=%NSIS_RES_DIR%\..\..\nsis

REM PostgreSQL Section
>%NSIS_RES_DIR%\postgres.def.nsh  ECHO !define PRODUCT_NAME "%PRODUCT_NAME%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_VERSION %PRODUCT_VERSION%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_PUBLISHER %PRODUCT_PUBLISHER%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_WEB_SITE %PRODUCT_WEB_SITE%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_DIR_REGKEY "%PRODUCT_DIR_REGKEY%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define OLD_PRODUCT_DIR_REGKEY "%OLD_PRODUCT_DIR_REGKEY%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_REG_KEY %PG_REG_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_REG_SERVICE_KEY %PG_REG_SERVICE_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_OLD_REG_KEY %PG_OLD_REG_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_OLD_REG_SERVICE_KEY %PG_OLD_REG_SERVICE_KEY%
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
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define BUILD_DIR %BUILD_DIR%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define SDK %SDK%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !addplugindir Plugins

IF "%ARCH%" == "X64" (
  >>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_64bit
)


CD /D %NSIS_RES_DIR% || GOTO :ERROR
makensis postgresql.nsi || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
