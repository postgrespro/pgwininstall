CALL %ROOT%\build\helpers\setvars.cmd
echo on
IF EXIST %DOWNLOADS_DIR%\%DEPS_ZIP% (
  7z x %DOWNLOADS_DIR%\%DEPS_ZIP% -o%DEPENDENCIES_BIN_DIR% -y
  REM Go to last build
  GOTO :BUILD_ALL
) ELSE (
  ECHO "You need to build dependencies first!"
  EXIT /B 1 || GOTO :ERROR
)

:BUILD_ALL

IF NOT "%NOLOAD_SRC%"=="" (
CD /D %BUILD_DIR%\postgresql\*%PGVER%* || GOTO :ERROR
GOTO :NOLOAD
)


:BUILD_POSTGRESQL
TITLE Building PostgreSQL...
CD /D %DOWNLOADS_DIR%
IF "%GIT_PATH%"=="" (
SET GIT_PATH=git://git.postgresql.org/git/postgresql.git
)
IF NOT "%GIT_BRANCH%"=="" (
rm -rf %BUILD_DIR%\postgresql
MKDIR %BUILD_DIR%\postgresql
MKDIR %BUILD_DIR%\postgresql\postgresql-%PGVER%
git clone -b %GIT_BRANCH% %GIT_PATH% %BUILD_DIR%\postgresql\postgresql-%PGVER%
CD /D %BUILD_DIR%\postgresql\*%PGVER%* || GOTO :ERROR

GOTO :NOTAR
)
wget --no-check-certificate %PGURL% -O postgresql-%PGVER%.tar.bz2 || GOTO :ERROR
rm -rf %BUILD_DIR%\postgresql
MKDIR %BUILD_DIR%\postgresql
%MSYS2_PATH%\tar xf postgresql-%PGVER%.tar.bz2 -C %BUILD_UDIR%/postgresql
CD /D %BUILD_DIR%\postgresql\*%PGVER%* || GOTO :ERROR
:NOTAR
IF %ONE_C% == YES (
  IF %HAVE_PGURL% == 1 SET PGTARNAME=postgrespro-1c
  IF NOT EXIST %ROOT%\patches\postgresql\%PG_MAJOR_VERSION%\series.for1c GOTO :DONE_1C_PATCH
  cp -va %ROOT%/patches/postgresql/%PG_MAJOR_VERSION%/series.for1c .
  FOR /F %%I IN (series.for1c) DO (
    ECHO %%I
    cp -va %ROOT%/patches/postgresql/%PG_MAJOR_VERSION%/%%I .
    patch -p1 < %%I || GOTO :ERROR
  )
)

:DONE_1C_PATCH

IF %SDK% == MSVC2017 (
  cp -va %ROOT%/patches/postgresql/2017.patch .
  patch -p1 < 2017.patch || GOTO :ERROR
)
IF %SDK% == MSVC2019 (
  cp -va %ROOT%/patches/postgresql/2017.patch .
  patch -p1 < 2017.patch || GOTO :ERROR
)


IF %HAVE_PGURL% == 0 (
  cp -va %ROOT%/patches/postgresql/%PG_MAJOR_VERSION%/series .
  IF NOT EXIST series GOTO :DONE_POSTGRESQL_PATCH
  FOR /F %%I IN (series) do (
    ECHO %%I
    cp -va %ROOT%/patches/postgresql/%PG_MAJOR_VERSION%/%%I .
    patch -p1 < %%I || GOTO :ERROR
  )
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
IF %SDK% == SDK71 GOTO :DISABLE_PERL
IF %ARCH% == X86 GOTO :DISABLE_PERL
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO perl    ^=^> '%PERL32_PATH%',   )
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO perl    ^=^> '%PERL64_PATH%',   )
GOTO :PERL_CONF_DONE
:DISABLE_PERL
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO perl    ^=^> undef,   )
:PERL_CONF_DONE
IF %ARCH% == X64 (>>src\tools\msvc\config.pl ECHO python  ^=^> '%PYTHON64_PATH%', )
IF %ARCH% == X86 (>>src\tools\msvc\config.pl ECHO python  ^=^> '%PYTHON32_PATH%', )
>>src\tools\msvc\config.pl ECHO openssl ^=^> '%DEPENDENCIES_BIN_DIR%\openssl',
>>src\tools\msvc\config.pl ECHO uuid    ^=^> '%DEPENDENCIES_BIN_DIR%\uuid',
>>src\tools\msvc\config.pl ECHO xml     ^=^> '%DEPENDENCIES_BIN_DIR%\libxml2',
>>src\tools\msvc\config.pl ECHO xslt    ^=^> '%DEPENDENCIES_BIN_DIR%\libxslt',
>>src\tools\msvc\config.pl ECHO iconv   ^=^> '%DEPENDENCIES_BIN_DIR%\iconv',
>>src\tools\msvc\config.pl ECHO zlib    ^=^> '%DEPENDENCIES_BIN_DIR%\zlib',
>>src\tools\msvc\config.pl ECHO icu     ^=^> '%DEPENDENCIES_BIN_DIR%\icu%ICU_VER%'
>>src\tools\msvc\config.pl ECHO ^};
>>src\tools\msvc\config.pl ECHO 1^;

REM IF %ONE_C% == YES (
REM   mv -v contrib\fulleq\fulleq.sql.in.in contrib\fulleq\fulleq.sql.in || GOTO :ERROR
REM )

SET DEPENDENCIES_BIN_DIR=%DEPENDENCIES_BIN_DIR:\=/%

cp -va %DEPENDENCIES_BIN_DIR%/icu%ICU_VER%/include/* src\include\ || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/icu%ICU_VER%/lib/*     . || GOTO :ERROR

:NOLOAD
REM IF %ARCH% == X86 SET PERL5LIB=%PERL32_PATH%\lib;src\tools\msvc;.
REM IF %ARCH% == X64 SET PERL5LIB=%PERL64_PATH%\lib;src\tools\msvc;.
SET PERL5LIB=%PERL64_PATH%\lib;src\tools\msvc;.

%PERL_EXE% src\tools\msvc\build.pl || GOTO :ERROR

rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
CD %BUILD_DIR%\postgresql\*%PGVER%*\src\tools\msvc

REM xcopy /Y %DEPENDENCIES_BIN_DIR%\libintl\lib\*.dll  %BUILD_DIR%\postgresql\*%PGVER%*\ || GOTO :ERROR
REM xcopy /Y %DEPENDENCIES_BIN_DIR%\iconv\lib\*.dll    %BUILD_DIR%\postgresql\*%PGVER%*\ || GOTO :ERROR
rem cp -va %DEPENDENCIES_BIN_DIR%/libintl/lib/libintl.dll	%BUILD_DIR%\postgresql\%PGTARNAME%-%PGVER%\ || GOTO :ERROR
rem cp -va %DEPENDENCIES_BIN_DIR%/iconv/lib/libiconv.dll    %BUILD_DIR%\postgresql\%PGTARNAME%-%PGVER%\ || GOTO :ERROR
rem cp -va %DEPENDENCIES_BIN_DIR%/iconv/lib/iconv.dll       %BUILD_DIR%\postgresql\%PGTARNAME%-%PGVER%\ || GOTO :ERROR

rem We need ICONV and LibIntl DLLS available during install for ZIC to work
rem no need to copy them, just add to PATH
PATH %PATH%;%DEPENDENCIES_BIN_DIR%\libintl\lib;%DEPENDENCIES_BIN_DIR%\iconv\lib
%PERL_EXE% install.pl %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql || GOTO :ERROR
IF EXIST ..\..\..\doc\buildinfo.txt COPY ..\..\..\doc\buildinfo.txt %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\doc
rem now actually copy DLLs of dependencies into our bindir
cp -va %DEPENDENCIES_BIN_DIR%/libintl/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/iconv/lib/*.dll      %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxml2/bin/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/lib/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/bin/*.dll    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
rem cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/VC/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/bin/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/bin/openssl.exe %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/zlib/lib/*.dll       %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/icu%ICU_VER%/bin/*.dll        %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\bin || GOTO :ERROR

REM Copy libraries headers to "include" directory for a God sake
cp -va %DEPENDENCIES_BIN_DIR%/libintl/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/iconv/include/*    %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxml2/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/include/*  %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/zlib/include/*     %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/uuid/include/*     %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\include || GOTO :ERROR

REM Copy import libraries to "lib' directory
cp -va %DEPENDENCIES_BIN_DIR%/libintl/lib/*.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/iconv/lib/*.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxml2/lib/libxml2.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/libxslt/lib/*t.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
rem cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/VC/*eay32.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/libssl.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/openssl/lib/libcrypto.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/zlib/lib/zdll.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/uuid/lib/uuid.lib %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib || GOTO :ERROR

SET LIBPGFEUTILS=%BUILD_DIR%/postgresql/*%PGVER%*/Release/libpgfeutils/libpgfeutils.lib
IF EXIST %LIBPGFEUTILS% cp -va %LIBPGFEUTILS% %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\lib || GOTO :ERROR

REM remove test_* extensions after install
rm -rf %BUILD_UDIR%/distr_%ARCH%_%PGVER%/postgresql/share/extension/test_* || GOTO :ERROR
rm -rf %BUILD_UDIR%/distr_%ARCH%_%PGVER%/postgresql/lib/test_* || GOTO :ERROR
rm -rf %BUILD_UDIR%/distr_%ARCH%_%PGVER%/postgresql/symbols/test_* || GOTO :ERROR

REM remove python3 extensions
rm -rf %BUILD_UDIR%/distr_%ARCH%_%PGVER%/postgresql/share/extension/*python3* || GOTO :ERROR
rm -rf %BUILD_UDIR%/distr_%ARCH%_%PGVER%/postgresql/lib/*python3* || GOTO :ERROR

SET WGET=wget --no-check-certificate

rem download help sources
CD /D %DOWNLOADS_DIR%
SET DOCURL=http://repo.postgrespro.ru/doc

%WGET% -O help-sources-en.zip %DOCURL%/pgsql/%PG_MAJOR_VERSION%/en/help-sources.zip || GOTO :ERROR
%WGET% -O help-sources-ru.zip %DOCURL%/pgsql/%PG_MAJOR_VERSION%/ru/help-sources.zip || GOTO :ERROR

rem building help files
CD /D %BUILD_DIR%\postgresql
rm -rf help-ru help-en
mkdir help-ru
mkdir help-en
CD help-ru
7z x %DOWNLOADS_DIR%\help-sources-ru.zip
CD help-ru
"C:\Program Files (x86)\HTML Help Workshop\hhc" htmlhelp.hhp
cp htmlhelp.chm %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\doc\postgresql-ru.chm || GOTO :ERROR
CD ..\help-en
7z x %DOWNLOADS_DIR%\help-sources-en.zip
CD help-en
"C:\Program Files (x86)\HTML Help Workshop\hhc" htmlhelp.hhp
cp htmlhelp.chm %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql\doc\postgresql-en.chm || GOTO :ERROR

7z a -r %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
REM PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
REM PAUSE
