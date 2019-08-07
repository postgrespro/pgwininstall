CALL %ROOT%\build\helpers\setvars.cmd

SET PROBACKUP_URL=https://github.com/postgrespro/pg_probackup/tarball/%PROBACKUP_VERSION%
SET BIN_DIR=%BUILD_DIR%\pg_probackup_%PG_MAJOR_VERSION%_%PROBACKUP_VERSION%_%ARCH%
SET PRODUCT_NAME=PostgreSQL

SET PGDIRSRC=%BUILD_DIR%\postgresql\postgresql-%PG_MAJOR_VERSION%\
SET PGDIR=Z:\inst\

SET PGDIR=Z:\Program Files\PostgresProEnterprise\11
SET PG_REG_KEY=SOFTWARE\PostgresPro\X64\PostgresProEnterprise\11\Installations\postgresql-11

SET INCLUDE=%INCLUDE%%PGDIR%\include\server;%PGDIR%\include\server\port\win32;%PGDIR%\include\server\port\win32_msvc;%PGDIR%\include;addsrc\;src\;
SET ARCHIVE=pg_probackup-%PROBACKUP_VERSION%.tar.gz

echo Download sources ...

rm -rf %BUILD_DIR%\pg_probackup || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup\pg_probackup-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION% || GOTO :ERROR

CD /D %BUILD_DIR%\pg_probackup\pg_probackup-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION% || GOTO :ERROR

wget --no-check-certificate %PROBACKUP_URL% -O %DOWNLOADS_DIR%\pg_probackup-%PROBACKUP_VERSION%.tar.bz2 || GOTO :ERROR
CD /D %DOWNLOADS_DIR% || GOTO :ERROR
tar xf pg_probackup-%PROBACKUP_VERSION%.tar.bz2 -C %BUILD_UDIR%/pg_probackup || GOTO :ERROR

CD /D %BUILD_DIR%\pg_probackup\*%PROBACKUP_VERSION%* || GOTO :ERROR

gen_probackup_project.pl %BUILD_DIR%\postgresql\postgresql-%PG_MAJOR_VERSION%

MKDIR %BIN_DIR% || GOTO :ERROR
MKDIR %BIN_DIR%\bin || GOTO :ERROR

rem copy pg_probackup binaries and dependencies
copy %BUILD_DIR%\postgresql\postgresql-%PG_MAJOR_VERSION%\Release\pg_probackup.exe %BIN_DIR% || GOTO :ERROR
copy %BUILD_DIR%\postgresql\postgresql-%PG_MAJOR_VERSION%\Release\libpq\libpq.dll %BIN_DIR% || GOTO :ERROR
copy %DEPENDENCIES_BIN_DIR%\zlib\lib\zlib1.dll %BIN_DIR% || GOTO :ERROR
copy %DEPENDENCIES_BIN_DIR%\openssl\lib\libeay32.dll %BIN_DIR% || GOTO :ERROR
copy %DEPENDENCIES_BIN_DIR%\openssl\lib\ssleay32.dll %BIN_DIR% || GOTO :ERROR

rem SET ZIP_FILE=pg-probackup-%PROBACKU_EDITION%-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION%-%ARCH%.zip
rem 7z.exe a .\..\out\pg_probackup.zip .\..\out\*.* -r
rem 7z.exe a .\..\%ZIP_FILE% .\..\out\*.* -r

goto :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
