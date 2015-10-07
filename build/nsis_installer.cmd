REM Required
REM 1. NSIS
REM 2. UsrMgr Plugin for NSIS
REM 3. AccessControl Plugin for NSIS
REM 4. Visual Studio 2010 Redistibutable (x86, x64) [Place it to nsis directory]
REM 5. PostgreSQL and PgAdmin3 binaries

REM Set your NSIS installation directory
SET NSIS_PATH="C:\Program Files (x86)\NSIS"
REM Add NSIS to your PATH
SET PATH=%PATH%;%NSIS_PATH%
REM Also, you need to make defines if you use x64 version of PostgreSQL
REM You need to uncomment this line: ;!define PG_64bit

REM ----------------------------------------------------------------------------
REM Assume, you have your PostgreSQL and PgAdmin3 build in C:\pg\distr_X86_9.4.4
REM For PostgreSQL you have 'postgresql' directory and
REM for PgAdmin3 you have 'pgadmin' directory
REM So you don't need to define PG_64bit in 'postgresql.nsi'
REM ----------------------------------------------------------------------------

REM Just run that script and installer will appear in the nsis directory

REM Set NSIS PostgreSQL Variables
SET DEFAULT_PORT=5432
SET DEFAULT_USER=postgres

SET PRODUCT_NAME=PostgreSQL
SET PG_MAJOR=9.4
SET PG_FULL=9.4.4
SET POSTGRES_ARCHITECTURE=x64

SET PRODUCT_PUBLISHER="Postgres Professional Russia"
SET COMPANY_NAME=PostgresPro
SET PRODUCT_WEB_SITE="http://postgrespro.ru"

SET PRODUCT_VERSION="%PG_MAJOR% (%POSTGRES_ARCHITECTURE%)"
SET PRODUCT_DIR_REGKEY="SOFTWARE\%COMPANY_NAME%\%POSTGRES_ARCHITECTURE%\%PRODUCT_NAME%\%PG_MAJOR%"
SET PG_REG_KEY="SOFTWARE\%COMPANY_NAME%\%POSTGRES_ARCHITECTURE%\%PRODUCT_NAME%\%PG_MAJOR%\Installations\postgresql-%PG_MAJOR%"
SET PG_REG_SERVICE_KEY="SOFTWARE\%COMPANY_NAME%\%POSTGRES_ARCHITECTURE%\%PRODUCT_NAME%\%PG_MAJOR%\Services\postgresql-%PG_MAJOR%"
SET PG_DEF_PORT="%DEFAULT_PORT%"
SET PG_DEF_SUPERUSER="%DEFAULT_USER%"
SET PG_DEF_SERVICEACCOUNT="NT AUTHORITY\NetworkService"
SET PG_DEF_SERVICEID="postgresql-%POSTGRES_ARCHITECTURE%-%PG_MAJOR%"
SET PG_DEF_VERSION_SHORT="%PG_MAJOR%"
SET PG_DEF_BRANDING="%PRODUCT_NAME% %PG_MAJOR% (%POSTGRES_ARCHITECTURE%)"
SET PG_INS_SUFFIX="%POSTGRES_ARCHITECTURE%bit_Setup.exe"
SET PG_INS_SOURCE_DIR="C:\pg\distr_%POSTGRES_ARCHITECTURE%_%PG_FULL%\postgresql\*.*"


SET NSIS_RES_DIR=%~dp0
SET NSIS_RES_DIR=%NSIS_RES_DIR:~0,-1%
SET NSIS_RES_DIR=%NSIS_RES_DIR%\..\nsis

REM PostgreSQL Section
>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_NAME "%PRODUCT_NAME%"
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_VERSION %PRODUCT_VERSION%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_PUBLISHER %PRODUCT_PUBLISHER%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_WEB_SITE %PRODUCT_WEB_SITE%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PRODUCT_DIR_REGKEY %PRODUCT_DIR_REGKEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_REG_KEY %PG_REG_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_REG_SERVICE_KEY %PG_REG_SERVICE_KEY%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_PORT %PG_DEF_PORT%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_SUPERUSER %PG_DEF_SUPERUSER%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_SERVICEACCOUNT %PG_DEF_SERVICEACCOUNT%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_SERVICEID %PG_DEF_SERVICEID%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_VERSION %PG_DEF_VERSION%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_VERSION_SHORT %PG_DEF_VERSION_SHORT%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_DEF_BRANDING %PG_DEF_BRANDING%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_INS_SUFFIX %PG_INS_SUFFIX%
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_INS_SOURCE_DIR %PG_INS_SOURCE_DIR%
IF %POSTGRES_ARCHITECTURE% == "x64" >>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_64bit

REM PgAdmin3 Section
SET PRODUCT_NAME=PgAdmin3
SET PGADMIN_VERSION=1.20
SET ADMIN_DEF_BRANDING="%PRODUCT_NAME% %PGADMIN_VERSION%"
SET ADMIN_DEF_VERSION="%PGADMIN_VERSION%"
SET PRODUCT_DIR_REGKEY="Software\%COMPANY_NAME%\%PRODUCT_NAME%\%PGADMIN_VERSION%"
SET ADMIN_REG_KEY="SOFTWARE\%COMPANY_NAME%\%PRODUCT_NAME%\%PGADMIN_VERSION%\Installations\"
SET ADMIN_INS_SUFFIX="%POSTGRES_ARCHITECTURE%bit_Setup.exe"
SET ADMIN_INS_SOURCE_DIR="C:\pg\distr_%POSTGRES_ARCHITECTURE%_%PG_FULL%\pgadmin\*.*"
>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_NAME "%PRODUCT_NAME%"
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_VERSION "%PGADMIN_VERSION%"
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_PUBLISHER %PRODUCT_PUBLISHER%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_WEB_SITE %PRODUCT_WEB_SITE%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_DIR_REGKEY %PRODUCT_DIR_REGKEY%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_REG_KEY %ADMIN_REG_KEY%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_DEF_VERSION %ADMIN_DEF_VERSION%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_DEF_BRANDING %ADMIN_DEF_BRANDING%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_INS_SUFFIX %ADMIN_INS_SUFFIX%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_INS_SOURCE_DIR %ADMIN_INS_SOURCE_DIR%
IF %POSTGRES_ARCHITECTURE% == "x64" >>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define Admin64

CD %NSIS_RES_DIR% || GOTO :ERROR
makensis postgresql.nsi || GOTO :ERROR
makensis pgadmin.nsi || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
