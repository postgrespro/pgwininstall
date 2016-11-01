CALL %ROOT%\build\helpers\setvars.cmd

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
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate %PGURL% -O postgresql-%PGVER%.tar.bz2 || GOTO :ERROR
rm -rf %BUILD_DIR%\postgresql
MKDIR %BUILD_DIR%\postgresql
tar xf postgres*-%PGVER%.tar.bz2 -C %BUILD_UDIR%/postgresql || GOTO :ERROR
CD /D %BUILD_DIR%\postgresql\*%PGVER%* || GOTO :ERROR

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
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO perl    ^=^> '%PERL32_PATH%',   )
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO python  ^=^> '%PYTHON64_PATH%', )
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO python  ^=^> '%PYTHON32_PATH%', )
>>src\tools\msvc\config.pl ECHO openssl ^=^> '%DEPENDENCIES_BIN_DIR%\openssl',
>>src\tools\msvc\config.pl ECHO uuid    ^=^> '%DEPENDENCIES_BIN_DIR%\uuid',
>>src\tools\msvc\config.pl ECHO xml     ^=^> '%DEPENDENCIES_BIN_DIR%\libxml2',
>>src\tools\msvc\config.pl ECHO xslt    ^=^> '%DEPENDENCIES_BIN_DIR%\libxslt',
>>src\tools\msvc\config.pl ECHO iconv   ^=^> '%DEPENDENCIES_BIN_DIR%\iconv',
>>src\tools\msvc\config.pl ECHO zlib    ^=^> '%DEPENDENCIES_BIN_DIR%\zlib',
>>src\tools\msvc\config.pl ECHO icu     ^=^> '%DEPENDENCIES_BIN_DIR%\icu',
>>src\tools\msvc\config.pl ECHO libedit ^=^> '%DEPENDENCIES_BIN_DIR%\wineditline'
>>src\tools\msvc\config.pl ECHO ^};
>>src\tools\msvc\config.pl ECHO 1^;

rem Setting pager
>>src\include\pg_config.h.win32 ECHO #define DEFAULT_PAGER "less -X"

IF %ONE_C% == YES (
  mv -v contrib\fulleq\fulleq.sql.in.in contrib\fulleq\fulleq.sql.in || GOTO :ERROR
rem With PostgresPro we'll use ICU libraries without copiing them
rem cp -va %DEPENDENCIES_BIN_DIR%/icu/include/* src\include\ || GOTO :ERROR
rem cp -va %DEPENDENCIES_BIN_DIR%/icu/lib/*     . || GOTO :ERROR

)

IF %ARCH% == X86 SET PERL5LIB=%PERL32_PATH%\lib;src\tools\msvc
IF %ARCH% == X64 SET PERL5LIB=%PERL64_PATH%\lib;src\tools\msvc

%PERL_EXE% src\tools\msvc\build.pl || GOTO :ERROR

rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
CD /D %BUILD_DIR%\postgresql\*%PGVER%*\src\tools\msvc


rem We need ICONV and LibIntl DLLS available during install for ZIC to work
rem no need to copy them, just add to PATH
PATH %PATH%;%DEPENDENCIES_BIN_DIR%\libintl\lib;%DEPENDENCIES_BIN_DIR%\iconv\lib
%PERL_EXE% install.pl %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql || GOTO :ERROR
rem now actually copy DLLs of dependencies into our bindir
cp -va %DEPENDENCIES_BIN_DIR%/libintl/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/iconv/lib/*.dll      %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxml2/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/VC/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/VC/openssl.exe %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/zlib/lib/*.dll       %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/icu/bin/*.dll        %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
REM Copy needed executables
cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/VC/openssl.exe %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/less/*.exe           %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR

REM Copy libraries headers to "include" directory for a God sake
cp -va %DEPENDENCIES_BIN_DIR%/libintl/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/iconv/include/*    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxml2/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/zlib/include/*     %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/uuid/include/*     %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR

rem Copy msys shell and sed
CD /D %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin
7z x %DOWNLOADS_DIR%\min_msys_%ARCH%.zip
rem CD /D %BUILD_DIR%\postgresql\*%PGVER%*\doc\src\sgml
rem cp -va html/* %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\doc

rem download help sources
CD /D %DOWNLOADS_DIR%
SET WGET=wget --no-check-certificate
SET DOCURL=http://repo.postgrespro.ru/doc

if "%PRODUCT_NAME%" == "PostgresPro" %WGET% -O help-sources-en.zip %DOCURL%/pgpro/9.6/en/help-sources.zip || GOTO :ERROR
if "%PRODUCT_NAME%" == "PostgresPro" %WGET% -O help-sources-ru.zip %DOCURL%/pgpro/9.6/ru/help-sources.zip || GOTO :ERROR
if "%PRODUCT_NAME%" == "PostgresProEnterprise" %WGET% -O help-sources-en.zip %DOCURL%/pgproee/9.6/en/help-sources.zip || GOTO :ERROR
if "%PRODUCT_NAME%" == "PostgresProEnterprise" %WGET% -O help-sources-ru.zip %DOCURL%/pgproee/9.6/ru/help-sources.zip || GOTO :ERROR
if "%PRODUCT_NAME%" == "PostgreSQL"  %WGET% -O help-sources-en.zip %DOCURL%/pgsql/9.6/en/help-sources.zip || GOTO :ERROR
if "%PRODUCT_NAME%" == "PostgreSQL"  %WGET% -O help-sources-ru.zip %DOCURL%/pgsql/9.6/ru/help-sources.zip || GOTO :ERROR

rem building help files
CD /D %BUILD_DIR%\postgresql
mkdir help-ru
mkdir help-en
CD help-ru
7z x %DOWNLOADS_DIR%\help-sources-ru.zip
CD help-ru
"C:\Program Files (x86)\HTML Help Workshop\hhc" htmlhelp.hhp
cp htmlhelp.chm %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\doc\postgresql-ru.chm
CD ..\help-en
7z x %DOWNLOADS_DIR%\help-sources-en.zip
CD help-en
"C:\Program Files (x86)\HTML Help Workshop\hhc" htmlhelp.hhp 
cp htmlhelp.chm %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\doc\postgresql-en.chm
7z a -r %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
