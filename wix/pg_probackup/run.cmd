SET ZIP_PATH=C:\Program Files\7-Zip;C:\Program Files (x86)\7-Zip
SET MSYS2_PATH=C:\msys64\usr\bin
SET PATH=%PATH%;%ZIP_PATH%;%MSYS2_PATH%;
rem SET ISDEV=1 for dev version of postgres
rem SET ISDEV= for stable version of postgres
IF EXIST config.cmd (
call config.cmd
GOTO :HAVECONFIG
)
rem PRODUCT_NAME may be PostgresProEnterprise or PostgresPro
IF "%PRODUCT_NAME%" == "" SET PRODUCT_NAME=PostgresPro
IF "%PG_MAJOR_VERSION%" == "" SET PG_MAJOR_VERSION=11
IF "%PG_PATCH_VERSION%" == "" SET PG_PATCH_VERSION=1.1
IF "%EDITION%" == "" SET EDITION=std
rem version of pg_probackup:
IF "%APPVERSION%" == "" SET APPVERSION=2.0.26
IF "%ARCH%" == "" SET ARCH=X64
:HAVECONFIG
SET COMPANY_NAME=PostgresPro
IF %ARCH% == X86 (
	SET BITS=32bit
) else (
	SET BITS=64bit
)

ECHO %PG_PATCH_VERSION% | grep "^[0-9]." > nul && (
  SET PGVER=%PG_MAJOR_VERSION%.%PG_PATCH_VERSION%
) || (
  SET PGVER=%PG_MAJOR_VERSION%%PG_PATCH_VERSION%
)

SET PG_INS_FILE=%PRODUCT_NAME%_%PGVER%_%BITS%_Setup.exe

rem Set reg key
SET PRODUCT_DIR_REGKEY=SOFTWARE\%COMPANY_NAME%\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%
SET PG_REG_KEY=%PRODUCT_DIR_REGKEY%\Installations\postgresql-%PG_MAJOR_VERSION%
rem echo PgVer=%PGVER%

rem set URLS for downloading
SET PRODUCT=pgpro-%PG_MAJOR_VERSION%
IF "%PRODUCT_NAME%" == "PostgresProEnterprise" (
  SET PRODUCT=pgproee-%PG_MAJOR_VERSION%
)

rem http://localrepo.l.postgrespro.ru/dev/<product>

SET URL_PART_ONE=http://localrepo.l.postgrespro.ru/dev/%PRODUCT%
IF "%ISDEV%" == "" (
SET URL_PART_ONE=http://repo.postgrespro.ru/%PRODUCT%-beta/
)

IF "%PG_MAJOR_VERSION%" == "9.6" SET PG_URL=%URL_PART_ONE%/src/postgrespro-%PGVER%.tar.bz2
IF NOT "%PG_MAJOR_VERSION%" == "9.6" SET PG_URL=%URL_PART_ONE%/src/postgrespro-standard-%PGVER%.tar.bz2

SET PG_INS_URL=%URL_PART_ONE%/win/%PG_INS_FILE%
SET PG_DEF_BRANDING=PostgresPro%PG_MAJOR_VERSION%
IF "%PRODUCT_NAME%" == "PostgresProEnterprise" (
SET PG_URL=%URL_PART_ONE%/src/postgrespro-enterprise-%PGVER%.tar.bz2
SET PG_INS_URL=%URL_PART_ONE%/win/%PG_INS_FILE%
SET PG_DEF_BRANDING=PostgresProEnterprise%PG_MAJOR_VERSION%
)
IF "%PRODUCT_NAME%" == "PostgreSql" (
SET PG_URL=https://ftp.postgresql.org/pub/source/v%PGVER%/postgresql-%PGVER%.tar.bz2
SET PG_INS_URL=https://repo.postgrespro.ru/win/64/PostgreSQL_%PGVER%_64bit_Setup.exe
SET PG_DEF_BRANDING=PostgreSQL%PG_MAJOR_VERSION%
SET COMPANY_NAME=Postgres Professional
SET PRODUCT_DIR_REGKEY=SOFTWARE\Postgres Professional\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%
SET PG_REG_KEY=SOFTWARE\Postgres Professional\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%\Installations\postgresql-%PG_MAJOR_VERSION%
)
rem GOTO :TEST
echo Downloading sources...
wget --no-check-certificate %PG_URL% -O postgresql-%PGVER%.tar.bz2 || GOTO :ERROR
rm -rf ./postgresql
MKDIR .\postgresql
tar xf postgres*-%PGVER%.tar.bz2 -C ./postgresql || GOTO :ERROR
mv ./postgresql/*%PGVER%*/* ./postgresql/

rem patch for readdir
rem will removed in the next postgres version
rem IF "%PRODUCT_NAME%" == "PostgreSql" (
rem CD postgresql
rem patch -f -p1 < ..\dirent.patch || GOTO :ERROR
rem cd ..
rem )
echo Downloading bins...
wget --no-check-certificate %PG_INS_URL% -O setup-%PGVER%.exe || GOTO :ERROR
rm -rf ./setup
7z.exe x setup-%PGVER%.exe -o./setup || GOTO :ERROR
:TEST
SET PGDIRSRC=.././postgresql
SET PGDIR=.././setup

call build_pro_backup.bat || GOTO :ERROR

goto :DONE
:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%
:DONE
ECHO Done.
