REM ----------------------------------------------------------------------------
REM Assume, you have your PostgreSQL and PgAdmin3 build in C:\pg\distr_X.._9.4...
REM For PostgreSQL you have 'postgresql' directory and
REM for PgAdmin3 you have 'pgadmin' directory
REM ----------------------------------------------------------------------------

SET PRODUCT_PUBLISHER="Postgres Professional Russia"
SET COMPANY_NAME=PostgresPro
SET PRODUCT_WEB_SITE="http://postgrespro.ru"

SET NSIS_RES_DIR=%~dp0
SET NSIS_RES_DIR=%NSIS_RES_DIR:~0,-1%
SET NSIS_RES_DIR=%NSIS_RES_DIR%\..\..\nsis

REM PgAdmin3 Section
SET PRODUCT_NAME=PgAdmin3
SET ADMIN_DEF_BRANDING="%PRODUCT_NAME% %PGADMIN_VERSION%"
SET ADMIN_DEF_VERSION="%PGADMIN_VERSION%"
SET PRODUCT_DIR_REGKEY="Software\%COMPANY_NAME%\%PRODUCT_NAME%\%PGADMIN_VERSION%"
SET ADMIN_REG_KEY="SOFTWARE\%COMPANY_NAME%\%PRODUCT_NAME%\%PGADMIN_VERSION%\Installations\"
SET ADMIN_INS_SUFFIX="%ARCH%bit_Setup.exe"
SET ADMIN_INS_SOURCE_DIR="%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\pgadmin\*.*"
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
>>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define REDIST_YEAR %REDIST_YEAR%
IF "%ARCH%" == "X64" (
  >>%NSIS_RES_DIR%\pgadmin.def.nsh ECHO !define Admin64
)

CD %NSIS_RES_DIR% || GOTO :ERROR
makensis pgadmin.nsi || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
