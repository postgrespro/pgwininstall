REM BUILD DEPENDS
REM 1. .NET 4.0
REM 2. MICROSOFT SDK 7.1
REM 3. ACTIVE PERL <= 5.14
REM 4. PYTHON 2.7
REM 5. MSYS2
REM 6. 7Z

REM Set 1C build (YES or NO)
SET ONEC=YES

REM SET POSTGRESQL VERSION
SET PGVER=9.4.5

REM SET ARCH: X86 or X64
SET ARCH=X64

SET PATH=%PATH%;C:\Program Files\7-Zip;C:\msys32\usr\bin
IF %ARCH% == X86 SET PATH=C:\Perl\Bin;%PATH%
IF %ARCH% == X64 SET PATH=C:\Perl64\Bin;%PATH%
CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv" /%ARCH% || GOTO :ERROR

pacman --noconfirm --sync flex bison tar wget patch

SET DOWNLOADS_DIR=c:\pg\downloads
MKDIR %DOWNLOADS_DIR%
SET DEPENDENCIES_DIR=c:\pg\dependencies

IF EXIST %DOWNLOADS_DIR%\deps_%ARCH%.zip (
  7z x %DOWNLOADS_DIR%\deps_%ARCH%.zip -o%DEPENDENCIES_DIR%
  REM GOTO LAST BUILD
  GOTO :BUILD_ALL
) ELSE (
  GOTO :ERROR
)

REM 7z x %DOWNLOADS_DIR%\deps_%ARCH%.zip -o %DEPENDENCIES_DIR% || GOTO :ERROR

REM GO TO LAST BUILD
GOTO :BUILD_ALL

:BUILD_ALL


:BUILD_POSTGRESQL
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://ftp.postgresql.org/pub/source/v%PGVER%/postgresql-%PGVER%.tar.bz2 -O postgresql-%PGVER%.tar.bz2
rm -rf c:\pg\postgresql
MKDIR c:\pg\postgresql
tar xf postgresql-%PGVER%.tar.bz2 -C c:\pg\postgresql
CD c:\pg\postgresql\postgresql-%PGVER%

IF %ONEC% == YES (
  cp -va c:/pgwininstall/patches/postgresql/%PGVER%/series.for1c .
  IF NOT EXIST series.for1c GOTO :ERROR
  FOR /F %%I IN (series.for1c) DO (
    ECHO %%I
    cp -va c:/pgwininstall/patches/postgresql/%PGVER%/%%I .
    patch -p1 < %%I || GOTO :ERROR
  )
)

cp -va c:/pgwininstall/patches/postgresql/%PGVER%/series .
IF NOT EXIST series GOTO :DONE_POSTGRESQL_PATCH
FOR /F %%I IN (series) do (
	ECHO %%I
	cp -va c:/pgwininstall/patches/postgresql/%PGVER%/%%I .
	patch -p1 < %%I || GOTO :ERROR
)
:DONE_POSTGRESQL_PATCH
>src\tools\msvc\config.pl  ECHO use strict;
>>src\tools\msvc\config.pl ECHO use warnings;
>>src\tools\msvc\config.pl ECHO our $config = {
>>src\tools\msvc\config.pl ECHO	asserts ^=^> 0^,    ^# --enable-cassert
>>src\tools\msvc\config.pl ECHO	^# integer_datetimes^=^>1,
>>src\tools\msvc\config.pl ECHO	^# float4byval^=^>1,
>>src\tools\msvc\config.pl ECHO	^# float8byval^=^>0,
>>src\tools\msvc\config.pl ECHO	^# blocksize ^=^> 8,
>>src\tools\msvc\config.pl ECHO	^# wal_blocksize ^=^> 8,
>>src\tools\msvc\config.pl ECHO	^# wal_segsize ^=^> 16,
>>src\tools\msvc\config.pl ECHO	ldap    ^=^> 1,
>>src\tools\msvc\config.pl ECHO	nls     ^=^> '%DEPENDENCIES_DIR%\libintl',
>>src\tools\msvc\config.pl ECHO	tcl     ^=^> undef,
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO	perl    ^=^> 'C:\Perl64',   )
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO	perl    ^=^> 'C:\Perl',     )
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO	python  ^=^> 'C:\Python27x64', )
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO	python  ^=^> 'C:\Python27x86', )
>>src\tools\msvc\config.pl ECHO	openssl ^=^> '%DEPENDENCIES_DIR%\openssl',
>>src\tools\msvc\config.pl ECHO	uuid    ^=^> '%DEPENDENCIES_DIR%\uuid',
>>src\tools\msvc\config.pl ECHO	xml     ^=^> '%DEPENDENCIES_DIR%\libxml2',
>>src\tools\msvc\config.pl ECHO	xslt    ^=^> '%DEPENDENCIES_DIR%\libxslt',
>>src\tools\msvc\config.pl ECHO	iconv   ^=^> '%DEPENDENCIES_DIR%\iconv',
>>src\tools\msvc\config.pl ECHO	zlib    ^=^> '%DEPENDENCIES_DIR%\zlib'
>>src\tools\msvc\config.pl ECHO ^};
>>src\tools\msvc\config.pl ECHO 1^;
IF %ONEC% == YES (
  REM Copy icu libs into postgres
  REM cp -va %DEPENDENCIES_DIR%\icu
  mv -v contrib\fulleq\fulleq.sql.in.in contrib\fulleq\fulleq.sql.in
  cp -va %DEPENDENCIES_DIR%/icu/include/* src\include\
  cp -va %DEPENDENCIES_DIR%/icu/lib/*     .
)

perl src\tools\msvc\build.pl || GOTO :ERROR
IF %ARCH% == X86 SET PERL5LIB=C:\Perl\lib;src\tools\msvc
IF %ARCH% == X64 SET PERL5LIB=C:\Perl64\lib;src\tools\msvc
rm -rf c:\pg\distr_%ARCH%_%PGVER%\postgresql
MKDIR c:\pg\distr_%ARCH%_%PGVER%\postgresql
CD c:\pg\postgresql\postgresql-%PGVER%\src\tools\msvc
cp -v %DEPENDENCIES_DIR%/libintl/lib/*.dll  c:\pg\postgresql\postgresql-%PGVER%\ || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/iconv/lib/*.dll    c:\pg\postgresql\postgresql-%PGVER%\ || GOTO :ERROR
perl install.pl c:\pg\distr_%ARCH%_%PGVER%\postgresql || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/libintl/lib/*.dll    c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/iconv/lib/*.dll      c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/libxml2/lib/*.dll    c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/libxslt/lib/*.dll    c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/openssl/lib/VC/*.dll c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_DIR%/zlib/lib/*.dll       c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
IF %ONEC% == YES cp -va %DEPENDENCIES_DIR%/icu/bin/*.dll c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR

:BUILD_PGADMIN
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://ftp.postgresql.org/pub/pgadmin3/release/v1.20.0/src/pgadmin3-1.20.0.tar.gz -O pgadmin3-1.20.0.tar.gz
rm -rf c:\pg\pgadmin
MKDIR c:\pg\pgadmin
tar xf pgadmin3-1.20.0.tar.gz -C c:\pg\pgadmin
CD c:\pg\pgadmin\pgadmin3-*
SET OPENSSL=%DEPENDENCIES_DIR%\openssl
SET WXWIN=%DEPENDENCIES_DIR%\wxwidgets
SET PGBUILD=%DEPENDENCIES_DIR%
SET PGDIR=c:\pg\distr_%ARCH%_%PGVER%\postgresql
SET PROJECTDIR=
cp -a %DEPENDENCIES_DIR%/libssh2/include/* pgadmin\include\libssh2 || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' xtra\png2c\png2c.vcxproj
IF %ARCH% == X64 sed -i 's/Win32/x64/g' pgadmin\pgAdmin3.vcxproj
sed -i "/<Bscmake>/,/<\/Bscmake>/d" pgadmin\pgAdmin3.vcxproj
IF %ARCH% == X86 msbuild xtra/png2c/png2c.vcxproj /p:Configuration="Release (3.0)" || GOTO :ERROR
IF %ARCH% == X64 msbuild xtra/png2c/png2c.vcxproj /p:Configuration="Release (3.0)" /p:Platform=x64 || GOTO :ERROR
cp -va xtra pgadmin || GOTO :ERROR
IF %ARCH% == X86 msbuild pgadmin/pgAdmin3.vcxproj /p:Configuration="Release (3.0)"
IF %ARCH% == X64 msbuild pgadmin/pgAdmin3.vcxproj /p:Configuration="Release (3.0)" /p:Platform=x64 || echo todo fix
rm -rf c:\pg\distr_%ARCH%_%PGVER%\pgadmin
MKDIR c:\pg\distr_%ARCH%_%PGVER%\pgadmin c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin c:\pg\distr_%ARCH%_%PGVER%\pgadmin\lib
cp -va pgadmin/Release*/*.exe c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR
cp -va i18n c:/pg/distr_%ARCH%_%PGVER%/pgadmin/bin  || GOTO :ERROR
cp -va c:/pg/distr_%ARCH%_%PGVER%/postgresql/bin/*.dll c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR
cp -va %DEPENDENCIES_DIR%/wxwidgets/lib/vc_dll/*.dll  c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR


GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
rm -rf %DEPENDENCIES_DIR%/*
ECHO Done.
PAUSE
