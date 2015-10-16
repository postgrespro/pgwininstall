REM Download VC Redistibutable packages
rm -rf "c:\pg\vcredist"
MKDIR "c:\pg\vcredist"
wget https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe -O "c:\pg\vcredist\vcredist_x86.exe"
wget https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe -O "c:\pg\vcredist\vcredist_x64.exe"

REM Make directory for installers
MKDIR "c:\pg\installers"

REM ----------------------------------------------------------------------------
REM Assume, you have your PostgreSQL and PgAdmin3 build in C:\pg\distr_X.._9.4...
REM For PostgreSQL you have 'postgresql' directory and
REM for PgAdmin3 you have 'pgadmin' directory
REM ----------------------------------------------------------------------------

REM Set NSIS PostgreSQL Variables
SET DEFAULT_PORT=5432
SET DEFAULT_USER=postgres

SET PRODUCT_NAME=PostgreSQL
SET PRODUCT_PUBLISHER="Postgres Professional Russia"
SET COMPANY_NAME=PostgresPro
SET PRODUCT_WEB_SITE="http://postgrespro.ru"

SET PRODUCT_VERSION="%PG_DEF_VERSION_SHORT% (%PG_ARCH%)"
SET PRODUCT_DIR_REGKEY="SOFTWARE\%COMPANY_NAME%\%PG_ARCH%\%PRODUCT_NAME%\%PG_DEF_VERSION_SHORT%"
SET PG_REG_KEY="SOFTWARE\%COMPANY_NAME%\%PG_ARCH%\%PRODUCT_NAME%\%PG_DEF_VERSION_SHORT%\Installations\postgresql-%PG_DEF_VERSION_SHORT%"
SET PG_REG_SERVICE_KEY="SOFTWARE\%COMPANY_NAME%\%PG_ARCH%\%PRODUCT_NAME%\%PG_DEF_VERSION_SHORT%\Services\postgresql-%PG_DEF_VERSION_SHORT%"
SET PG_DEF_PORT="%DEFAULT_PORT%"
SET PG_DEF_SUPERUSER="%DEFAULT_USER%"
SET PG_DEF_SERVICEACCOUNT="NT AUTHORITY\NetworkService"
SET PG_DEF_SERVICEID="postgresql-%PG_ARCH%-%PG_DEF_VERSION_SHORT%"
SET PG_DEF_BRANDING="%PRODUCT_NAME% %PG_DEF_VERSION_SHORT% (%PG_ARCH%)"
SET PG_INS_SUFFIX="%PG_ARCH%bit_Setup.exe"
SET PG_INS_SOURCE_DIR="C:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\postgresql\*.*"


SET NSIS_RES_DIR=%~dp0
SET NSIS_RES_DIR=%NSIS_RES_DIR:~0,-1%
SET NSIS_RES_DIR=%NSIS_RES_DIR%\..\..\nsis

REM PostgreSQL Section
>%NSIS_RES_DIR%\postgres.def.nsh  ECHO !define PRODUCT_NAME "%PRODUCT_NAME%"
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
IF "%PG_ARCH%" == "X64" (
>>%NSIS_RES_DIR%\postgres.def.nsh ECHO !define PG_64bit
)

REM PgAdmin3 Section
SET PRODUCT_NAME=PgAdmin3
SET ADMIN_DEF_BRANDING="%PRODUCT_NAME% %PGADMIN_VERSION%"
SET ADMIN_DEF_VERSION="%PGADMIN_VERSION%"
SET PRODUCT_DIR_REGKEY="Software\%COMPANY_NAME%\%PRODUCT_NAME%\%PGADMIN_VERSION%"
SET ADMIN_REG_KEY="SOFTWARE\%COMPANY_NAME%\%PRODUCT_NAME%\%PGADMIN_VERSION%\Installations\"
SET ADMIN_INS_SUFFIX="%PG_ARCH%bit_Setup.exe"
SET ADMIN_INS_SOURCE_DIR="C:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\pgadmin\*.*"
>%NSIS_RES_DIR%\pgadmin.def.nsh  ECHO !define PRODUCT_NAME "%PRODUCT_NAME%"
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_VERSION "%PGADMIN_VERSION%"
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_PUBLISHER %PRODUCT_PUBLISHER%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_WEB_SITE %PRODUCT_WEB_SITE%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define PRODUCT_DIR_REGKEY %PRODUCT_DIR_REGKEY%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_REG_KEY %ADMIN_REG_KEY%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_DEF_VERSION %ADMIN_DEF_VERSION%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_DEF_BRANDING %ADMIN_DEF_BRANDING%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_INS_SUFFIX %ADMIN_INS_SUFFIX%
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define ADMIN_INS_SOURCE_DIR %ADMIN_INS_SOURCE_DIR%
IF "%PG_ARCH%" == "X64" (
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define Admin64
)

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
