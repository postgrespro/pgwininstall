CALL %ROOT%\build\helpers\setvars.cmd

SET PROBACKUP_URL=https://github.com/postgrespro/pg_probackup/tarball/%PROBACKUP_VERSION%
SET PRODUCT_NAME=""

IF %PROBACKUP_EDITION% == vanilla (
   SET PRODUCT_NAME=PostgreSQL
)

IF %PROBACKUP_EDITION% == std (
  SET PRODUCT_NAME=PostgresPro
)

IF %PRODUCT_NAME% == "" (
	ECHO Invalid PROBACKUP_EDITION: %PROBACKUP_EDITION%
	GOTO :ERROR
)

SET BIN_DIR=%BUILD_DIR%\pg_probackup_%PROBACKUP_EDITION%_%PG_MAJOR_VERSION%_%PROBACKUP_VERSION%_%ARCH%

echo Download sources ...

rm -rf %BUILD_DIR%\pg_probackup || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup\pg_probackup-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION% || GOTO :ERROR

CD /D %BUILD_DIR%\pg_probackup\pg_probackup-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION% || GOTO :ERROR

git clone https://github.com/postgrespro/pg_probackup . || GOTO :ERROR

perl gen_probackup_project.pl %BUILD_DIR%\postgresql\postgresql-%PGVER% || GOTO :ERROR

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
