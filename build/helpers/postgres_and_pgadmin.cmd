IF EXIST %DOWNLOADS_DIR%\%DEPS_ZIP% (
  7z x %DOWNLOADS_DIR%\%DEPS_ZIP% -o%DEPENDENCIES_BIN_DIR% -y
  REM Go to last build
  GOTO :BUILD_ALL
) ELSE (
  ECHO "You need to build dependencies first!"
  EXIT /B 1 || GOTO :ERROR
)

:BUILD_ALL

:BUILD_POSTGRESQL
TITLE Building PostgreSQL...
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://ftp.postgresql.org/pub/source/v%PGVER%/postgresql-%PGVER%.tar.bz2 -O postgresql-%PGVER%.tar.bz2 || GOTO :ERROR
rm -rf %BUILD_DIR%\postgresql
MKDIR %BUILD_DIR%\postgresql
tar xf postgresql-%PGVER%.tar.bz2 -C %BUILD_DIR%\postgresql
CD %BUILD_DIR%\postgresql\postgresql-%PGVER%

IF %ONE_C% == YES (
  cp -va %ROOT%/patches/postgresql/%PGVER%/series.for1c .
  IF NOT EXIST series.for1c GOTO :ERROR
  FOR /F %%I IN (series.for1c) DO (
    ECHO %%I
    cp -va %ROOT%/patches/postgresql/%PGVER%/%%I .
    patch -p1 < %%I || GOTO :ERROR
  )
)

cp -va %ROOT%/patches/postgresql/%PGVER%/series .
IF NOT EXIST series GOTO :DONE_POSTGRESQL_PATCH
FOR /F %%I IN (series) do (
  ECHO %%I
  cp -va %ROOT%/patches/postgresql/%PGVER%/%%I .
  patch -p1 < %%I || GOTO :ERROR
)
:DONE_POSTGRESQL_PATCH
>src\tools\msvc\config.pl  ECHO use strict;
>>src\tools\msvc\config.pl ECHO use warnings;
>>src\tools\msvc\config.pl ECHO our $config = {
>>src\tools\msvc\config.pl ECHO asserts ^=^> 0^,    ^# --enable-cassert
>>src\tools\msvc\config.pl ECHO ^# integer_datetimes^=^>1,
>>src\tools\msvc\config.pl ECHO ^# float4byval^=^>1,
>>src\tools\msvc\config.pl ECHO ^# float8byval^=^>0,
>>src\tools\msvc\config.pl ECHO ^# blocksize ^=^> 8,
>>src\tools\msvc\config.pl ECHO ^# wal_blocksize ^=^> 8,
>>src\tools\msvc\config.pl ECHO ^# wal_segsize ^=^> 16,
>>src\tools\msvc\config.pl ECHO ldap    ^=^> 1,
>>src\tools\msvc\config.pl ECHO nls     ^=^> '%DEPENDENCIES_BIN_DIR%\libintl',
>>src\tools\msvc\config.pl ECHO tcl     ^=^> undef,
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO perl    ^=^> '%PERL64_PATH%',   )
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO perl    ^=^> '%PERL32_PATH%',     )
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO python  ^=^> '%PYTHON64_PATH%', )
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO python  ^=^> '%PYTHON32_PATH%', )
>>src\tools\msvc\config.pl ECHO openssl ^=^> '%DEPENDENCIES_BIN_DIR%\openssl',
>>src\tools\msvc\config.pl ECHO uuid    ^=^> '%DEPENDENCIES_BIN_DIR%\uuid',
>>src\tools\msvc\config.pl ECHO xml     ^=^> '%DEPENDENCIES_BIN_DIR%\libxml2',
>>src\tools\msvc\config.pl ECHO xslt    ^=^> '%DEPENDENCIES_BIN_DIR%\libxslt',
>>src\tools\msvc\config.pl ECHO iconv   ^=^> '%DEPENDENCIES_BIN_DIR%\iconv',
>>src\tools\msvc\config.pl ECHO zlib    ^=^> '%DEPENDENCIES_BIN_DIR%\zlib'
>>src\tools\msvc\config.pl ECHO ^};
>>src\tools\msvc\config.pl ECHO 1^;
IF %ONE_C% == YES (
  mv -v contrib\fulleq\fulleq.sql.in.in contrib\fulleq\fulleq.sql.in
  cp -va %DEPENDENCIES_BIN_DIR%/icu/include/* src\include\
  cp -va %DEPENDENCIES_BIN_DIR%/icu/lib/*     .
)

perl src\tools\msvc\build.pl || GOTO :ERROR
IF %ARCH% == X86 SET PERL5LIB=%PERL32_PATH%\lib;src\tools\msvc
IF %ARCH% == X64 SET PERL5LIB=%PERL64_PATH%\lib;src\tools\msvc
rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
CD %BUILD_DIR%\postgresql\postgresql-%PGVER%\src\tools\msvc
cp -v %DEPENDENCIES_BIN_DIR%/libintl/lib/*.dll  %BUILD_DIR%\postgresql\postgresql-%PGVER%\ || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/iconv/lib/*.dll    %BUILD_DIR%\postgresql\postgresql-%PGVER%\ || GOTO :ERROR

perl install.pl %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/libintl/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/iconv/lib/*.dll      %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/libxml2/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/libxslt/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/openssl/lib/VC/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -v %DEPENDENCIES_BIN_DIR%/zlib/lib/*.dll       %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
IF %ONE_C% == YES cp -va %DEPENDENCIES_BIN_DIR%/icu/bin/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR

REM Copy libraries headers to "include" directory for a God sake
cp -va %DEPENDENCIES_BIN_DIR%/libintl/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/iconv/include/*    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxml2/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/zlib/include/*     %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/uuid/include/*     %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR

7z a -r %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql


:BUILD_PGADMIN
TITLE Building PgAdmin3...
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://ftp.postgresql.org/pub/pgadmin3/release/v%PGADMIN_VERSION%/src/pgadmin3-%PGADMIN_VERSION%.tar.gz -O pgadmin3-%PGADMIN_VERSION%.tar.gz
rm -rf %BUILD_DIR%\pgadmin
MKDIR %BUILD_DIR%\pgadmin
tar xf pgadmin3-%PGADMIN_VERSION%.tar.gz -C %BUILD_DIR%\pgadmin
CD %BUILD_DIR%\pgadmin\pgadmin3-*
SET OPENSSL=%DEPENDENCIES_BIN_DIR%\openssl
SET WXWIN=%DEPENDENCIES_BIN_DIR%\wxwidgets
SET PGBUILD=%DEPENDENCIES_BIN_DIR%
SET PGDIR=%BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
SET PROJECTDIR=
cp -a %DEPENDENCIES_BIN_DIR%/libssh2/include/* pgadmin\include\libssh2 || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' xtra\png2c\png2c.vcxproj
IF %ARCH% == X64 sed -i 's/Win32/x64/g' pgadmin\pgAdmin3.vcxproj
sed -i "/<Bscmake>/,/<\/Bscmake>/d" pgadmin\pgAdmin3.vcxproj
IF %ARCH% == X86 msbuild xtra/png2c/png2c.vcxproj /m /p:Configuration="Release (3.0)" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
IF %ARCH% == X64 msbuild xtra/png2c/png2c.vcxproj /m /p:Configuration="Release (3.0)" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
cp -va xtra pgadmin || GOTO :ERROR
IF %ARCH% == X86 msbuild pgadmin/pgAdmin3.vcxproj /m /p:Configuration="Release (3.0)" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
IF %ARCH% == X64 msbuild pgadmin/pgAdmin3.vcxproj /m /p:Configuration="Release (3.0)" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\lib
cp -va pgadmin/Release*/*.exe %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR
cp -va i18n c:/pg/distr_%ARCH%_%PGVER%/pgadmin/bin  || GOTO :ERROR
cp -va c:/pg/distr_%ARCH%_%PGVER%/postgresql/bin/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/wxwidgets/lib/vc_dll/*.dll  %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR


GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
