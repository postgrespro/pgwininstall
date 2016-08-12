CALL %ROOT%\build\helpers\setvars.cmd

IF  EXIST %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql (
	ECHO "PostgreSQL version %PGVER% already build"
) ELSE (
	IF EXIST %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip (
		7z x %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip -o%BUILD_DIR%\distr_%ARCH%_%PGVER% -y
	) ELSE (
		ECHO "You need to build PostgreSQL first!"
		EXIT /B 1 || GOTO :ERROR
	)
)

:BUILD_PGODBC
TITLE Building PgODBC...
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate -c https://ftp.postgresql.org/pub/odbc/versions/src/psqlodbc-%PG_ODBC_VERSION%.tar.gz
rm -rf %BUILD_DIR%\pgodbc
MKDIR %BUILD_DIR%\pgodbc
tar xf psqlodbc-%PG_ODBC_VERSION%.tar.gz -C %BUILD_UDIR%/pgodbc
CD /D %BUILD_DIR%\pgodbc\psqlodbc-%PG_ODBC_VERSION%

>>windows-local.mak ECHO PG_INC=%BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include
>>windows-local.mak ECHO PG_LIB=%BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib
>>windows-local.mak ECHO TARGET_CPU=%ARCH%

nmake -f win64.mak || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
