CALL %ROOT%\build\helpers\setvars.cmd

SET PROBACKUP_URL=https://github.com/postgrespro/pg_probackup/tarball/%PROBACKUP_VERSION%
SET BIN_DIR=%BUILD_DIR%\pg_probackup_%PG_MAJOR_VERSION%_%PROBACKUP_VERSION%_%ARCH%

IF %PROBACKUP_EDITION% == vanilla (
   SET PRODUCT_NAME=PostgreSQL
)
ELSE IF %PROBACKUP_EDITION% == std (
  SET PRODUCT_NAME=PostgresPro
)
ELSE (
	ECHO Invalid PROBACKUP_EDITION: %PROBACKUP_EDITION%
	GOTO :ERROR
)

echo Download sources ...

rm -rf %BUILD_DIR%\pg_probackup || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup\pg_probackup-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION% || GOTO :ERROR

CD /D %BUILD_DIR%\pg_probackup\pg_probackup-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION% || GOTO :ERROR

git clone https://github.com/postgrespro/pg_probackup .

gen_probackup_project.pl %BUILD_DIR%\postgresql\postgresql-%PGVER%

rm -rf %BIN_DIR% || GOTO :ERROR
MKDIR %BIN_DIR% || GOTO :ERROR

copy %BUILD_DIR%\postgresql\postgresql-%PGVER%\Release\pg_probackup\pg_probackup.exe %BIN_DIR% || GOTO :ERROR
copy %BUILD_DIR%\postgresql\postgresql-%PGVER%\Release\libpq\libpq.dll %BIN_DIR% || GOTO :ERROR
copy %DEPENDENCIES_BIN_DIR%\zlib\lib\zlib1.dll %BIN_DIR% || GOTO :ERROR
copy %DEPENDENCIES_BIN_DIR%\openssl\lib\libeay32.dll %BIN_DIR% || GOTO :ERROR
copy %DEPENDENCIES_BIN_DIR%\openssl\lib\ssleay32.dll %BIN_DIR% || GOTO :ERROR

goto :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
