CALL %ROOT%\build\helpers\setvars.cmd

REM Make ZIP of binaries
TITLE Make PostgreSQL and PgAdmin3 archives
IF %ONE_C% == YES (
  7z a "%BUILD_DIR%\installers\postgrespro-1c-%ARCH%-%PG_DEF_VERSION%.zip" "%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
) ELSE (
  7z a "%BUILD_DIR%\installers\postgresql-%ARCH%-%PG_DEF_VERSION%.zip" "%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
)
7z a "%BUILD_DIR%\installers\pgAdmin3-%ARCH%-%PG_DEF_VERSION%.zip" "%BUILD_DIR%\distr_%ARCH%_%PG_DEF_VERSION%\pgadmin" || EXIT /b %errorlevel%
