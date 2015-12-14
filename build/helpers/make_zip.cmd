REM Make ZIP of binaries
IF %ONE_C% == YES (
  7z a "c:\pg\installers\postgrespro-1c-%ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
) ELSE (
  7z a "c:\pg\installers\postgresql-%ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%ARCH%_%PG_DEF_VERSION%\postgresql" || EXIT /b %errorlevel%
)
7z a "c:\pg\installers\pgAdmin3-%ARCH%-%PG_DEF_VERSION%.zip" "c:\pg\distr_%ARCH%_%PG_DEF_VERSION%\pgadmin" || EXIT /b %errorlevel%
