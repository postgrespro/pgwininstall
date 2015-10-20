REM Make ZIP of binaries
IF %ONEC% == YES (
  7z a "c:\pg\installers\postgrespro-1c-%PG_ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
) ELSE (
  7z a "c:\pg\installers\postgresql-%PG_ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
)
7z a "c:\pg\installers\pgAdmin3-%PG_ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%PG_ARCH%_%PG_DEF_VERSION%\pgadmin" || EXIT /b %errorlevel%
