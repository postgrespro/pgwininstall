REM Make ZIP of binaries
REM Make PostgreSQL binaries ZIP
7z a "c:\pg\installers\postgresql-%PG_ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
REM Make PgAdmin3 binaries ZIP
7z a "c:\pg\installers\pgAdmin3-%PG_ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\pgadmin" || EXIT /b %errorlevel%
