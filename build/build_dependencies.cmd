REM What you need:
REM 1. Windows 7.1 SDK
REM 2. .NET 4.0
REM 3. Msys2
REM 4. 7zip

REM SET ARCH: X86 or X64
SET ARCH=X64

SET PATH=%PATH%;C:\Program Files\7-Zip;C:\msys32\usr\bin
IF %ARCH% == X86 SET PATH=C:\Perl\Bin;%PATH%
IF %ARCH% == X64 SET PATH=C:\Perl64\Bin;%PATH%
CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv" /%ARCH% || GOTO :ERROR

pacman --noconfirm --sync flex bison tar wget patch


MKDIR c:\pg
MKDIR c:\pg\dependencies
MKDIR c:\pg\downloads

REM GOTO LAST BUILD
GOTO :BUILD_ALL

:BUILD_ALL
SET DEPENDENCIES_DIR=c:\pg\dependencies
SET DOWNLOADS_DIR=c:\pg\downloads

:BUILD_ICONV
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz -O libiconv-1.14.tar.gz
wget --no-check-certificate -c https://raw.githubusercontent.com/postgrespro/pgwininstall/master/patches/libiconv-1.14.patch -O libiconv-1.14.patch
rm -rf %DEPENDENCIES_DIR%\iconv || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\iconv
tar xf libiconv-1.14.tar.gz -C %DEPENDENCIES_DIR%\iconv || GOTO :ERROR
CD %DEPENDENCIES_DIR%\iconv\libiconv-1.14*
cp -v %DOWNLOADS_DIR%\libiconv-1.14.patch .
patch -p0 < libiconv-1.14.patch || GOTO :ERROR
IF %ARCH% == X64 msbuild libiconv.vcxproj /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X86 msbuild libiconv.vcxproj /p:Configuration=Release || GOTO :ERROR
cp -av include %DEPENDENCIES_DIR%\iconv || GOTO :ERROR
cp -av iconv.h %DEPENDENCIES_DIR%\iconv\include || GOTO :ERROR
cp -av config.h %DEPENDENCIES_DIR%\iconv\include || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\iconv\lib
cp -av Release*/*.dll %DEPENDENCIES_DIR%\iconv\lib || GOTO :ERROR
cp -av Release*/libiconv.dll %DEPENDENCIES_DIR%\iconv\lib\iconv.dll || GOTO :ERROR
cp -av Release*/*.lib %DEPENDENCIES_DIR%\iconv\lib || GOTO :ERROR
cp -av Release*/libiconv.lib %DEPENDENCIES_DIR%\iconv\lib\iconv.lib || GOTO :ERROR
cp -av lib %DEPENDENCIES_DIR%\iconv\libiconv || GOTO :ERROR


:BUILD_ZLIB
CD %DOWNLOADS_DIR%
wget -c http://zlib.net/zlib-1.2.8.tar.gz -O zlib-1.2.8.tar.gz
rm -rf "%DEPENDENCIES_DIR%\zlib
MKDIR "%DEPENDENCIES_DIR%\zlib
tar xf zlib-1.2.8.tar.gz -C "%DEPENDENCIES_DIR%\zlib
CD "%DEPENDENCIES_DIR%\zlib\zlib*
nmake -f win32/Makefile.msc || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\zlib\lib %DEPENDENCIES_DIR%\zlib\include
cp -v *.lib %DEPENDENCIES_DIR%\zlib\lib || GOTO :ERROR
cp -v *.dll %DEPENDENCIES_DIR%\zlib\lib || GOTO :ERROR
cp -v *.pdb %DEPENDENCIES_DIR%\zlib\lib || GOTO :ERROR
cp -v *.h %DEPENDENCIES_DIR%\zlib\include || GOTO :ERROR


:BUILD_UUID
CD %DOWNLOADS_DIR%
wget -c http://netcologne.dl.sourceforge.net/project/osspuuidwin32/src/ossp_uuid_1.6.2_win32_source_120608.7z -O ossp_uuid_1.6.2_win32_source_120608.7z
rm -rf %DEPENDENCIES_DIR%\uuid
MKDIR %DEPENDENCIES_DIR%\uuid
CD %DEPENDENCIES_DIR%\uuid
7z x %DOWNLOADS_DIR%\ossp_uuid_1.6.2_win32_source_120608.7z
CD %DEPENDENCIES_DIR%\uuid\ossp_uuid
IF %ARCH% == X64 sed -i 's/Win32/x64/g' ossp_uuid.sln || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' ossp_uuid\ossp_uuid.vcxproj || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' example\example.vcxproj || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' uuid_cli\uuid_cli.vcxproj || GOTO :ERROR
IF %ARCH% == X64 msbuild ossp_uuid.sln /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X86 msbuild ossp_uuid.sln /p:Configuration=Release || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\uuid\lib
cp -av include %DEPENDENCIES_DIR%\uuid || GOTO :ERROR
IF %ARCH% == X64 cp -av x64\Release\ossp_uuid.lib %DEPENDENCIES_DIR%\uuid\lib\uuid.lib || GOTO :ERROR
IF %ARCH% == X86 cp -av Release\ossp_uuid.lib %DEPENDENCIES_DIR%\uuid\lib\uuid.lib || GOTO :ERROR


:BUILD_XML
CD %DOWNLOADS_DIR%
wget -c ftp://xmlsoft.org/libxml2/libxml2-2.7.3.tar.gz -O libxml2-2.7.3.tar.gz
rm -rf %DEPENDENCIES_DIR%\libxml2
MKDIR %DEPENDENCIES_DIR%\libxml2
tar xf libxml2-2.7.3.tar.gz -C %DEPENDENCIES_DIR%\libxml2
CD %DEPENDENCIES_DIR%\libxml2\libxml2-*\win32
cscript configure.js compiler=msvc include=%DEPENDENCIES_DIR%\iconv\include lib=%DEPENDENCIES_DIR%\iconv\lib
sed -i /NOWIN98/d Makefile.msvc
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin %DEPENDENCIES_DIR%\libxml2 || GOTO :ERROR
cp -av lib %DEPENDENCIES_DIR%\libxml2 || GOTO :ERROR
cp -av include %DEPENDENCIES_DIR%\libxml2 || GOTO :ERROR


:BUILD_XSLT
CD %DOWNLOADS_DIR%
wget -c ftp://xmlsoft.org/libxslt/libxslt-1.1.28.tar.gz -O libxslt-1.1.28.tar.gz
rm -rf %DEPENDENCIES_DIR%\libxslt
MKDIR %DEPENDENCIES_DIR%\libxslt
tar xf libxslt-1.1.28.tar.gz -C %DEPENDENCIES_DIR%\libxslt
CD %DEPENDENCIES_DIR%\libxslt\libxslt-*\win32
cscript configure.js compiler=msvc zlib=yes iconv=yes include=%DEPENDENCIES_DIR%\iconv\include;%DEPENDENCIES_DIR%\libxml2\include;%DEPENDENCIES_DIR%\zlib\include lib=%DEPENDENCIES_DIR%\iconv\lib;%DEPENDENCIES_DIR%\libxml2\lib;%DEPENDENCIES_DIR%\zlib\lib
sed -i /NOWIN98/d Makefile.msvc
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin %DEPENDENCIES_DIR%\libxslt || GOTO :ERROR
cp -av lib %DEPENDENCIES_DIR%\libxslt || GOTO :ERROR
cp -av include %DEPENDENCIES_DIR%\libxslt || GOTO :ERROR


:BUILD_OPENSSL
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://www.openssl.org/source/openssl-1.0.2d.tar.gz -O openssl-1.0.2d.tar.gz
rm -rf %DEPENDENCIES_DIR%\openssl
MKDIR %DEPENDENCIES_DIR%\openssl
tar xf openssl-1.0.2d.tar.gz -C %DEPENDENCIES_DIR%\openssl
CD %DEPENDENCIES_DIR%\openssl\openssl-*
IF %ARCH% == X86 perl Configure VC-WIN32 no-asm   || GOTO :ERROR
IF %ARCH% == X64 perl Configure VC-WIN64A no-asm  || GOTO :ERROR
IF %ARCH% == X86 call ms\do_ms
IF %ARCH% == X64 call ms\do_win64a.bat
nmake -f ms\ntdll.mak || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\openssl\lib
cp -av out32dll/* %DEPENDENCIES_DIR%\openssl\lib || GOTO :ERROR
cp -av include    %DEPENDENCIES_DIR%\openssl || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\openssl\lib\VC
cp -av out32dll/*           %DEPENDENCIES_DIR%\openssl\lib\VC || GOTO :ERROR
cp -v out32dll/ssleay32.lib %DEPENDENCIES_DIR%\openssl\lib\VC\ssleay32MD.lib || GOTO :ERROR
cp -v out32dll/libeay32.lib %DEPENDENCIES_DIR%\openssl\lib\VC\libeay32MD.lib || GOTO :ERROR


:BUILD_LIBINTL
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://ftp.gnu.org/gnu/gettext/gettext-0.19.4.tar.gz -O gettext-0.19.4.tar.gz
rm -rf %DEPENDENCIES_DIR%\libintl
MKDIR %DEPENDENCIES_DIR%\libintl
tar xf gettext-0.19.4.tar.gz -C %DEPENDENCIES_DIR%\libintl
CD  %DEPENDENCIES_DIR%\libintl\gettext-*
cp -v c:/pgwininstall/patches/gettext-0.19.4.patch .
patch -p0 < gettext-0.19.4.patch || GOTO :ERROR
IF %ARCH% == X64 msbuild libintl.vcxproj /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X86 msbuild libintl.vcxproj /p:Configuration=Release || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\libintl\lib %DEPENDENCIES_DIR%\libintl\include
cp -v Release*/*.dll  %DEPENDENCIES_DIR%\libintl\lib || GOTO :ERROR
cp -v Release*/*.lib  %DEPENDENCIES_DIR%\libintl\lib || GOTO :ERROR
cp -v libintl.h       %DEPENDENCIES_DIR%\libintl\include\libintl.h || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\libintl\bin
>%DEPENDENCIES_DIR%\libintl\bin\msgfmt.cmd ECHO msgfmt %%^*


:BUILD_LIBSSH2
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://www.libssh2.org/download/libssh2-1.4.3.tar.gz -O libssh2-1.4.3.tar.gz
rm -rf %DEPENDENCIES_DIR%\libssh2
MKDIR %DEPENDENCIES_DIR%\libssh2
tar xf libssh2-1.4.3.tar.gz -C %DEPENDENCIES_DIR%\libssh2
cp -va %DEPENDENCIES_DIR%/libssh2/libssh2-*/include %DEPENDENCIES_DIR%\libssh2\include  || GOTO :ERROR
cp -va %DEPENDENCIES_DIR%/libssh2/libssh2-*/win32/libssh2_config.h %DEPENDENCIES_DIR%\libssh2\include  || GOTO :ERROR


:BUILD_WXWIDGETS
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://sourceforge.net/projects/wxwindows/files/3.0.2/wxWidgets-3.0.2.tar.bz2 -O wxWidgets-3.0.2.tar.bz2
rm -rf %DEPENDENCIES_DIR%\wxwidgets
MKDIR %DEPENDENCIES_DIR%\wxwidgets
tar xf wxWidgets-3.0.2.tar.bz2 -C %DEPENDENCIES_DIR%\wxwidgets
CD %DEPENDENCIES_DIR%\wxwidgets\wxWidgets-*
IF %ARCH% == X86 msbuild build\msw\wx_vc10.sln  /p:Configuration="Release" || GOTO :ERROR
IF %ARCH% == X86 msbuild build\msw\wx_vc10.sln  /p:Configuration="DLL Release" || GOTO :ERROR
IF %ARCH% == X64 msbuild build\msw\wx_vc10.sln  /p:Configuration="Release" /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X64 msbuild build\msw\wx_vc10.sln  /p:Configuration="DLL Release" /p:Platform=x64 || GOTO :ERROR
cp -va %DEPENDENCIES_DIR%/wxwidgets/wxWidgets-3*/lib      %DEPENDENCIES_DIR%\wxwidgets  || GOTO :ERROR
IF %ARCH% == X64 cp -va %DEPENDENCIES_DIR%/wxwidgets/lib/vc_*dll   %DEPENDENCIES_DIR%\wxwidgets\lib\vc_dll  || GOTO :ERROR
IF %ARCH% == X64 cp -va %DEPENDENCIES_DIR%/wxwidgets/lib/vc_*lib   %DEPENDENCIES_DIR%\wxwidgets\lib\vc_lib  || GOTO :ERROR
cp -va %DEPENDENCIES_DIR%/wxwidgets/wxWidgets-3*/include  %DEPENDENCIES_DIR%\wxwidgets\include  || GOTO :ERROR


GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
