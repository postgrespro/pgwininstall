REM BUILD DEPENDS
REM 1. .NET 4.0
REM 2. MICROSOFT SDK 7.1
REM 3. ACTIVE PERL <= 5.14
REM 4. PYTHON 2.7
REM 5. MSYS2
REM 6. 7Z

REM SET POSTGRESQL VERSION
SET PGVER=9.4.5

REM SET ARCH: X86 or X64
SET ARCH=X64

SET PATH=%PATH%;C:\Program Files\7-Zip;C:\msys32\usr\bin
IF "%ARCH%" == "X86" SET PATH=C:\Perl\Bin;%PATH%
IF "%ARCH%" == "X64" SET PATH=C:\Perl64\Bin;%PATH%
CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv" /%ARCH% || GOTO :ERROR

pacman --noconfirm --sync flex bison tar wget patch

REM GOTO LAST BUILD
GOTO :BUILD_ALL

:BUILD_ALL
MKDIR "c:\pg\download"

:BUILD_ICONV
CD "c:\pg\download"
wget --no-check-certificate -c http://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz -O libiconv-1.14.tar.gz
wget --no-check-certificate -c https://raw.githubusercontent.com/postgrespro/pgwininstall/master/patches/libiconv-1.14.patch -O libiconv-1.14.patch
rm -rf "c:\pg\iconv" || GOTO :ERROR
MKDIR "c:\pg\iconv"
tar xf libiconv-1.14.tar.gz -C "c:\pg\iconv" || GOTO :ERROR
CD "c:\pg\iconv\libiconv-1.14*"
cp -v "c:\pg\download\libiconv-1.14.patch" .
patch -p0 < libiconv-1.14.patch || GOTO :ERROR
IF "%ARCH%" == "X64" msbuild libiconv.vcxproj /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF "%ARCH%" == "X86" msbuild libiconv.vcxproj /p:Configuration=Release || GOTO :ERROR
cp -av include "c:\pg\iconv" || GOTO :ERROR
cp -av iconv.h "c:\pg\iconv\include" || GOTO :ERROR
cp -av config.h "c:\pg\iconv\include" || GOTO :ERROR
MKDIR "c:\pg\iconv\lib"
cp -av Release*/*.dll "c:\pg\iconv\lib" || GOTO :ERROR
cp -av Release*/libiconv.dll "c:\pg\iconv\lib\iconv.dll" || GOTO :ERROR
cp -av Release*/*.lib "c:\pg\iconv\lib" || GOTO :ERROR
cp -av Release*/libiconv.lib "c:\pg\iconv\lib\iconv.lib" || GOTO :ERROR
cp -av lib "c:\pg\iconv\libiconv" || GOTO :ERROR


:BUILD_ZLIB
CD "c:\pg\download"
wget -c http://zlib.net/zlib-1.2.8.tar.gz -O zlib-1.2.8.tar.gz
rm -rf "c:\pg\zlib"
MKDIR "c:\pg\zlib"
tar xf zlib-1.2.8.tar.gz -C "c:\pg\zlib"
CD "c:\pg\zlib\zlib*"
nmake -f win32/Makefile.msc || GOTO :ERROR
MKDIR "c:\pg\zlib\lib" "c:\pg\zlib\include"
cp -v *.lib "c:\pg\zlib\lib" || GOTO :ERROR
cp -v *.dll "c:\pg\zlib\lib" || GOTO :ERROR
cp -v *.pdb "c:\pg\zlib\lib" || GOTO :ERROR
cp -v *.h "c:\pg\zlib\include" || GOTO :ERROR


:BUILD_UUID
CD "c:\pg\download"
wget -c http://netcologne.dl.sourceforge.net/project/osspuuidwin32/src/ossp_uuid_1.6.2_win32_source_120608.7z -O ossp_uuid_1.6.2_win32_source_120608.7z
rm -rf "c:\pg\uuid"
MKDIR "c:\pg\uuid"
CD "c:\pg\uuid"
7z x c:\pg\download\ossp_uuid_1.6.2_win32_source_120608.7z
CD "C:\pg\uuid\ossp_uuid"
IF "%ARCH%" == "X64" sed -i 's/Win32/x64/g' ossp_uuid.sln || GOTO :ERROR
IF "%ARCH%" == "X64" sed -i 's/Win32/x64/g' ossp_uuid\ossp_uuid.vcxproj || GOTO :ERROR
IF "%ARCH%" == "X64" sed -i 's/Win32/x64/g' example\example.vcxproj || GOTO :ERROR
IF "%ARCH%" == "X64" sed -i 's/Win32/x64/g' uuid_cli\uuid_cli.vcxproj || GOTO :ERROR
IF "%ARCH%" == "X64" msbuild ossp_uuid.sln /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF "%ARCH%" == "X86" msbuild ossp_uuid.sln /p:Configuration=Release || GOTO :ERROR
MKDIR "c:\pg\uuid\lib"
cp -av include "c:\pg\uuid" || GOTO :ERROR
IF "%ARCH%" == "X64" cp -av x64/Release/ossp_uuid.lib "c:\pg\uuid\lib\uuid.lib" || GOTO :ERROR
IF "%ARCH%" == "X86" cp -av Release/ossp_uuid.lib "c:\pg\uuid\lib\uuid.lib" || GOTO :ERROR


:BUILD_XML
CD "c:\pg\download"
wget -c ftp://xmlsoft.org/libxml2/libxml2-2.7.3.tar.gz -O libxml2-2.7.3.tar.gz
rm -rf "c:\pg\libxml2"
MKDIR "c:\pg\libxml2"
tar xf libxml2-2.7.3.tar.gz -C "c:\pg\libxml2"
CD "c:\pg\libxml2\libxml2-*\win32"
cscript configure.js compiler=msvc include=C:\pg\iconv\include lib=c:\pg\iconv\lib
sed -i /NOWIN98/d Makefile.msvc
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin "c:\pg\libxml2" || GOTO :ERROR
cp -av lib "c:\pg\libxml2" || GOTO :ERROR
cp -av include "c:\pg\libxml2" || GOTO :ERROR


:BUILD_XSLT
CD "c:\pg\download"
wget -c ftp://xmlsoft.org/libxslt/libxslt-1.1.28.tar.gz -O libxslt-1.1.28.tar.gz
rm -rf "c:\pg\libxslt"
MKDIR "c:\pg\libxslt"
tar xf libxslt-1.1.28.tar.gz -C "c:\pg\libxslt"
CD "c:\pg\libxslt\libxslt-*\win32"
cscript configure.js compiler=msvc zlib=yes iconv=yes include=C:\pg\iconv\include;c:\pg\libxml2\include;c:\pg\zlib\include lib=c:\pg\iconv\lib;c:\pg\libxml2\lib;c:\pg\zlib\lib
sed -i /NOWIN98/d Makefile.msvc
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin "c:\pg\libxslt" || GOTO :ERROR
cp -av lib "c:\pg\libxslt" || GOTO :ERROR
cp -av include "c:\pg\libxslt" || GOTO :ERROR


:BUILD_OPENSSL
CD "c:\pg\download"
wget --no-check-certificate -c https://www.openssl.org/source/openssl-1.0.2d.tar.gz -O openssl-1.0.2d.tar.gz
rm -rf "c:\pg\openssl"
MKDIR "c:\pg\openssl"
tar xf openssl-1.0.2d.tar.gz -C "c:\pg\openssl"
CD "c:\pg\openssl\openssl-*"
IF "%ARCH%" == "X86" perl Configure VC-WIN32 no-asm || GOTO :ERROR
IF "%ARCH%" == "X64" perl Configure VC-WIN64A no-asm || GOTO :ERROR
IF "%ARCH%" == "X86" call ms\do_ms
IF "%ARCH%" == "X64" call ms\do_win64a.bat
nmake -f ms\ntdll.mak || GOTO :ERROR
MKDIR "c:\pg\openssl\lib"
cp -av out32dll/* "c:\pg\openssl\lib" || GOTO :ERROR
cp -av include "c:\pg\openssl" || GOTO :ERROR
MKDIR "c:\pg\openssl\lib\VC"
cp -av out32dll/* "c:\pg\openssl\lib\VC" || GOTO :ERROR
cp -v out32dll/ssleay32.lib "c:\pg\openssl\lib\VC\ssleay32MD.lib" || GOTO :ERROR
cp -v out32dll/libeay32.lib "c:\pg\openssl\lib\VC\libeay32MD.lib" || GOTO :ERROR


:BUILD_LIBINTL
CD "c:\pg\download"
wget --no-check-certificate -c http://ftp.gnu.org/gnu/gettext/gettext-0.19.4.tar.gz -O gettext-0.19.4.tar.gz
wget --no-check-certificate -c https://raw.githubusercontent.com/postgrespro/pgwininstall/master/patches/gettext-0.19.4.patch -O gettext-0.19.4.patch
rm -rf "c:\pg\libintl"
MKDIR "c:\pg\libintl"
tar xf gettext-0.19.4.tar.gz -C "c:\pg\libintl"
CD  "c:\pg\libintl\gettext-*"
cp -v "c:\pg\download\gettext-0.19.4.patch" .
patch -p0 < gettext-0.19.4.patch || GOTO :ERROR
IF "%ARCH%" == "X64" msbuild libintl.vcxproj /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF "%ARCH%" == "X86" msbuild libintl.vcxproj /p:Configuration=Release || GOTO :ERROR
MKDIR "c:\pg\libintl\lib" "c:\pg\libintl\include"
cp -v Release*/*.dll "c:\pg\libintl\lib" || GOTO :ERROR
cp -v Release*/*.lib "c:\pg\libintl\lib" || GOTO :ERROR
cp -v libintl.h "c:\pg\libintl\include\libintl.h" || GOTO :ERROR
MKDIR "c:\pg\libintl\bin"
>c:\pg\libintl\bin\msgfmt.cmd ECHO msgfmt %%^*

:BUILD_POSTGRESQL
CD "c:\pg\download"
wget --no-check-certificate -c https://ftp.postgresql.org/pub/source/v%PGVER%/postgresql-%PGVER%.tar.bz2 -O postgresql-%PGVER%.tar.bz2
rm -rf "c:\pg\postgresql"
MKDIR "c:\pg\postgresql"
tar xf postgresql-%PGVER%.tar.bz2 -C "c:\pg\postgresql"
CD "c:\pg\postgresql\postgresql-%PGVER%"
wget --no-check-certificate -c https://raw.githubusercontent.com/postgrespro/pgwininstall/master/patches/postgresql/%PGVER%/series -O series
IF NOT EXIST series GOTO :DONE_POSTGRESQL_PATCH
FOR /F %%I IN (series) do (
	ECHO %%I
	wget --no-check-certificate -c https://raw.githubusercontent.com/postgrespro/pgwininstall/master/patches/postgresql/%PGVER%/%%I -O %%I
	patch -p1 < %%%I || GOTO :ERROR
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
>>src\tools\msvc\config.pl ECHO	nls     ^=^> 'C:\pg\libintl',
>>src\tools\msvc\config.pl ECHO	tcl     ^=^> undef,
IF "%ARCH%" == "X64" (>>src\tools\msvc\config.pl ECHO	perl    ^=^> 'C:\Perl64',   )
IF "%ARCH%" == "X86" (>>src\tools\msvc\config.pl ECHO	perl    ^=^> 'C:\Perl',     )
IF "%ARCH%" == "X64" (>>src\tools\msvc\config.pl ECHO	python  ^=^> 'C:\Python27x64', )
IF "%ARCH%" == "X86" (>>src\tools\msvc\config.pl ECHO	python  ^=^> 'C:\Python27x86', )
>>src\tools\msvc\config.pl ECHO	openssl ^=^> 'c:\pg\openssl',
>>src\tools\msvc\config.pl ECHO	uuid    ^=^> 'c:\pg\uuid',
>>src\tools\msvc\config.pl ECHO	xml     ^=^> 'c:\pg\libxml2',
>>src\tools\msvc\config.pl ECHO	xslt    ^=^> 'c:\pg\libxslt',
>>src\tools\msvc\config.pl ECHO	iconv   ^=^> 'C:\pg\iconv',
>>src\tools\msvc\config.pl ECHO	zlib    ^=^> 'c:\pg\zlib'
>>src\tools\msvc\config.pl ECHO ^};
>>src\tools\msvc\config.pl ECHO 1^;
perl src\tools\msvc\build.pl || GOTO :ERROR
IF "%ARCH%" == "X86" SET PERL5LIB=C:\Perl\lib;src\tools\msvc
IF "%ARCH%" == "X64" SET PERL5LIB=C:\Perl64\lib;src\tools\msvc
rm -rf c:\pg\distr_%ARCH%_%PGVER%\postgresql
MKDIR "c:\pg\distr_%ARCH%_%PGVER%\postgresql"
CD "c:\pg\postgresql\postgresql-%PGVER%\src\tools\msvc"
cp -v c:/pg/libintl/lib/*.dll c:\pg\postgresql\postgresql-%PGVER%\ || GOTO :ERROR
cp -v c:/pg/iconv/lib/*.dll c:\pg\postgresql\postgresql-%PGVER%\ || GOTO :ERROR
perl install.pl c:\pg\distr_%ARCH%_%PGVER%\postgresql || GOTO :ERROR
cp -v c:/pg/libintl/lib/*.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
cp -v c:/pg/iconv/lib/*.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
cp -v c:/pg/libxml2/lib/*.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
cp -v c:/pg/libxslt/lib/*.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
cp -v c:/pg/openssl/lib/VC/*.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
cp -v c:/pg/zlib/lib/*.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
IF "%ARCH%" == "X86" cp -v c:/Perl/bin/perl514.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR
IF "%ARCH%" == "X64" cp -v c:/Perl64/bin/perl514.dll "c:\pg\distr_%ARCH%_%PGVER%\postgresql\bin" || GOTO :ERROR

:BUILD_LIBSSH2
CD "c:\pg\download"
wget --no-check-certificate -c http://www.libssh2.org/download/libssh2-1.4.3.tar.gz -O libssh2-1.4.3.tar.gz
rm -rf "c:\pg\libssh2"
MKDIR "c:\pg\libssh2"
tar xf libssh2-1.4.3.tar.gz -C "c:\pg\libssh2"
cp -va c:/pg/libssh2/libssh2-*/include "c:\pg\libssh2\include"  || GOTO :ERROR
cp -va c:/pg/libssh2/libssh2-*/win32/libssh2_config.h "c:\pg\libssh2\include"  || GOTO :ERROR


:BUILD_WXWIDGETS
CD "c:\pg\download"
wget --no-check-certificate -c https://sourceforge.net/projects/wxwindows/files/3.0.2/wxWidgets-3.0.2.tar.bz2 -O wxWidgets-3.0.2.tar.bz2
rm -rf "c:\pg\wxwidgets"
MKDIR "c:\pg\wxwidgets"
tar xf wxWidgets-3.0.2.tar.bz2 -C "c:\pg\wxwidgets"
CD "c:\pg\wxwidgets\wxWidgets-*"
IF "%ARCH%" == "X86" msbuild build\msw\wx_vc10.sln  /p:Configuration="Release" || GOTO :ERROR
IF "%ARCH%" == "X86" msbuild build\msw\wx_vc10.sln  /p:Configuration="DLL Release" || GOTO :ERROR
IF "%ARCH%" == "X64" msbuild build\msw\wx_vc10.sln  /p:Configuration="Release" /p:Platform=x64 || GOTO :ERROR
IF "%ARCH%" == "X64" msbuild build\msw\wx_vc10.sln  /p:Configuration="DLL Release" /p:Platform=x64 || GOTO :ERROR
cp -va c:/pg/wxwidgets/wxWidgets-3*/lib c:\pg\wxwidgets  || GOTO :ERROR
IF "%ARCH%" == "X64" cp -va c:/pg/wxwidgets/lib/vc_*dll c:\pg\wxwidgets\lib\vc_dll  || GOTO :ERROR
IF "%ARCH%" == "X64" cp -va c:/pg/wxwidgets/lib/vc_*lib c:\pg\wxwidgets\lib\vc_lib  || GOTO :ERROR
cp -va c:/pg/wxwidgets/wxWidgets-3*/include c:\pg\wxwidgets\include  || GOTO :ERROR


:BUILD_PGADMIN
CD "c:\pg\download"
wget --no-check-certificate -c https://ftp.postgresql.org/pub/pgadmin3/release/v1.20.0/src/pgadmin3-1.20.0.tar.gz -O pgadmin3-1.20.0.tar.gz
rm -rf "c:\pg\pgadmin"
MKDIR "c:\pg\pgadmin"
tar xf pgadmin3-1.20.0.tar.gz -C "c:\pg\pgadmin"
CD c:\pg\pgadmin\pgadmin3-*
SET OPENSSL=c:\pg\openssl
SET WXWIN=c:\pg\wxwidgets
SET PGBUILD=c:\pg
SET PGDIR=c:\pg\distr_%ARCH%_%PGVER%\postgresql
SET PROJECTDIR=
cp -a c:/pg/libssh2/include/* pgadmin\include\libssh2 || GOTO :ERROR
IF "%ARCH%" == "X64" sed -i 's/Win32/x64/g' xtra\png2c\png2c.vcxproj
IF "%ARCH%" == "X64" sed -i 's/Win32/x64/g' pgadmin\pgAdmin3.vcxproj
sed -i "/<Bscmake>/,/<\/Bscmake>/d" pgadmin\pgAdmin3.vcxproj
IF "%ARCH%" == "X86" msbuild xtra/png2c/png2c.vcxproj /p:Configuration="Release (3.0)" || GOTO :ERROR
IF "%ARCH%" == "X64" msbuild xtra/png2c/png2c.vcxproj /p:Configuration="Release (3.0)" /p:Platform=x64 || GOTO :ERROR
cp -va xtra pgadmin || GOTO :ERROR
IF "%ARCH%" == "X86" msbuild pgadmin/pgAdmin3.vcxproj /p:Configuration="Release (3.0)"
IF "%ARCH%" == "X64" msbuild pgadmin/pgAdmin3.vcxproj /p:Configuration="Release (3.0)" /p:Platform=x64 || echo todo fix
rm -rf "c:\pg\distr_%ARCH%_%PGVER%\pgadmin"
MKDIR "c:\pg\distr_%ARCH%_%PGVER%\pgadmin" "c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin" "c:\pg\distr_%ARCH%_%PGVER%\pgadmin\lib"
cp -va pgadmin/Release*/*.exe "c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin"  || GOTO :ERROR
cp -va i18n "c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin"  || GOTO :ERROR
cp -va c:/pg/distr_%ARCH%_%PGVER%/postgresql/bin/*.dll "c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin"  || GOTO :ERROR
cp -va c:/pg/wxwidgets/lib/vc_dll/*.dll  "c:\pg\distr_%ARCH%_%PGVER%\pgadmin\bin"  || GOTO :ERROR


GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
