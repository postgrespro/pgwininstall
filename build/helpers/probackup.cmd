SET PGDIRSRC=Z:\extension-packaging\pg_probackup\windows\postgresql
SET PGDIR=Z:\inst\
SET PGDIRSRC=Z:\pgwininstall\builddir\postgresql\postgresql-11.2.1
SET PGDIR=Z:\Program Files\PostgresProEnterprise\11
SET APPVERSION=2.1.1
SET PG_REG_KEY=SOFTWARE\PostgresPro\X64\PostgresProEnterprise\11\Installations\postgresql-11
SET PG_DEF_BRANDING=PostgresPro Enterprise 11
SET PRODUCT_NAME=PostgresProEnterprise
SET BITS=64bit
SET PGVER=11.1.1
SET EDITION=vanilla
SET APPVERSION=2.1.1
SET PRODUCT_NAME=PostgreSQL

SET PERL5LIB=.

rem GOTO :INS
SET LIB=%LIB%%PGDIR%\lib;
SET INCLUDE=%INCLUDE%%PGDIR%\include\server;%PGDIR%\include\server\port\win32;%PGDIR%\include\server\port\win32_msvc;%PGDIR%\include;addsrc\;src\;
set CPU=AMD64
REM GOTO :INS
SET ARCHIVE=pg_probackup-%APPVERSION%.tar.gz
IF NOT exist .\pg_probackup (
echo Download sources ...
git clone https://github.com/postgrespro/pg_probackup.git -b %APPVERSION% || goto :ERROR
REM wget -O "%ARCHIVE%"  "http://localrepo.l.postgrespro.ru/tarballs/extensions/%ARCHIVE%" || goto :ERROR
REM MKDIR .\pg_probackup
REM tar xf %ARCHIVE% -C .\pg_probackup
)

perl genres.pl  "pg_probackup for PostgreSQL" %APPVERSION% exe || GOTO :ERROR
cp win32ver.rc ./pg_probackup
cp win32.ico ./pg_probackup
CD pg_probackup
mkdir addsrc
cp "%PGDIRSRC%/src/backend/access/transam/xlogreader.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/backend/utils/hash/pg_crc.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_basebackup/receivelog.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_basebackup/receivelog.h" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_basebackup/streamutil.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_basebackup/streamutil.h" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_basebackup/walmethods.c" addsrc
cp "%PGDIRSRC%/src/bin/pg_basebackup/walmethods.h" addsrc
cp "%PGDIRSRC%/src/bin/pg_rewind/datapagemap.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_rewind/datapagemap.h" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/bin/pg_rewind/logging.h" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/timezone/strftime.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/timezone/private.h" addsrc || goto :ERROR

cp "%PGDIRSRC%/src/interfaces/libpq/pthread-win32.c" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/interfaces/libpq/pqexpbuffer.h" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/interfaces/libpq/libpq-int.h" addsrc || goto :ERROR
cp "%PGDIRSRC%/src/port/pthread-win32.h" addsrc || goto :ERROR
mkdir addsrc\port
cp "%PGDIRSRC%/src/port/pthread-win32.h" addsrc/port/ || goto :ERROR

rc.exe win32ver.rc
CL /MD /O2 src\*.c src\utils\*.c addsrc\*.c /DWIN32 /DFRONTEND /Fepg_probackup.exe /link ws2_32.lib advapi32.lib libpq.lib libpgport.lib libintl.lib zdll.lib iconv.lib libpgcommon.lib win32ver.res  || goto :ERROR
rem libecpg.lib -> libpgtypes.lib libpgfeutils.lib 
mkdir .\..\out
mkdir .\..\out\bin
copy pg_probackup.exe .\..\out\bin

mkdir .\..\out_full
copy pg_probackup.exe .\..\out_full
cp "%PGDIR%/bin/libpq.dll" ./../out_full
cp "%PGDIR%/bin/zlib1.dll" ./../out_full
cp "%PGDIR%/bin/libintl.dll" ./../out_full
cp "%PGDIR%/bin/libeay32.dll" ./../out_full
cp "%PGDIR%/bin/libiconv.dll" ./../out_full
cp "%PGDIR%/bin/ssleay32.dll" ./../out_full
rem copy C:\Windows\System32\msvcr120.dll .\..\out_full

rem SET ZIP_FILE=%PRODUCT_NAME%_%PGVER%_%BITS%_Pg_probackup%APPVERSION%.zip
SET ZIP_FILE=pg-probackup-%EDITION%-%PG_MAJOR_VERSION%-%APPVERSION%-%BITS%.zip
rem 7z.exe a .\..\out\pg_probackup.zip .\..\out\*.* -r
7z.exe a .\..\%ZIP_FILE% .\..\out\*.* -r

goto :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
