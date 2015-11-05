REM What you need:
REM 1. Windows 7.1 SDK
REM 2. .NET 4.0
REM 3. Msys2
REM 4. 7zip

REM SET ARCH: X86 or X64
SET ARCH=X64

REM Magic to set root directory of those scripts
@echo off&setlocal
FOR %%i in ("%~dp0..") do set "ROOT=%%~fi"

SET PATH=%PATH%;C:\Program Files\7-Zip;C:\msys32\usr\bin
IF %ARCH% == X86 SET PATH=C:\Perl\Bin;%PATH%
IF %ARCH% == X64 SET PATH=C:\Perl64\Bin;%PATH%
CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv" /%ARCH% || GOTO :ERROR

pacman --noconfirm --sync flex bison tar wget patch

MKDIR c:\pg
MKDIR c:\pg\dependencies
MKDIR c:\pg\dependencies_src
MKDIR c:\pg\downloads

SET DEPENDENCIES_SRC_DIR=c:\pg\dependencies_src
SET DEPENDENCIES_BIN_DIR=c:\pg\dependencies
SET DOWNLOADS_DIR=c:\pg\downloads

REM LIBRARY VERSIONS
SET GEOS_VER=3.4.2
SET PROJ_VER=4.6.1
SET GDAL_VER=1.6.3
SET JSONC_VER=1757a31750134577faf80b91d0cf6f98d3918e6c
SET ICONV_VER=1.14
SET XSLT_VER=1.1.28
SET ZLIB_VER=1.2.8
SET XML_VER=2.7.3
SET OPENSSL_VER=1.0.2d
SET GETTEXT_VER=0.19.4
SET LIBSSH2_VER=1.4.3
SET WXWIDGETS_VER=3.0.2

REM GOTO LAST BUILD
GOTO :BUILD_ALL

:BUILD_ALL


:BUILD_ICONV
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://ftp.gnu.org/gnu/libiconv/libiconv-%ICONV_VER%.tar.gz -O libiconv-%ICONV_VER%.tar.gz
wget --no-check-certificate -c https://raw.githubusercontent.com/postgrespro/pgwininstall/master/patches/libiconv-%ICONV_VER%.patch -O libiconv-%ICONV_VER%.patch
rm -rf %DEPENDENCIES_BIN_DIR%\iconv
MKDIR %DEPENDENCIES_BIN_DIR%\iconv
tar xf libiconv-%ICONV_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\libiconv-%ICONV_VER%*
cp -v %DOWNLOADS_DIR%\libiconv-%ICONV_VER%.patch .
patch -f -p0 < libiconv-%ICONV_VER%.patch || GOTO :ERROR
IF %ARCH% == X64 msbuild libiconv.vcxproj /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X86 msbuild libiconv.vcxproj /p:Configuration=Release || GOTO :ERROR
cp -av include %DEPENDENCIES_BIN_DIR%\iconv || GOTO :ERROR
cp -av iconv.h %DEPENDENCIES_BIN_DIR%\iconv\include || GOTO :ERROR
cp -av config.h %DEPENDENCIES_BIN_DIR%\iconv\include || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\iconv\lib
cp -av Release*/*.dll %DEPENDENCIES_BIN_DIR%\iconv\lib || GOTO :ERROR
cp -av Release*/libiconv.dll %DEPENDENCIES_BIN_DIR%\iconv\lib\iconv.dll || GOTO :ERROR
cp -av Release*/*.lib %DEPENDENCIES_BIN_DIR%\iconv\lib || GOTO :ERROR
cp -av Release*/libiconv.lib %DEPENDENCIES_BIN_DIR%\iconv\lib\iconv.lib || GOTO :ERROR
cp -av lib %DEPENDENCIES_BIN_DIR%\iconv\libiconv || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\iconv


:BUILD_ZLIB
CD %DOWNLOADS_DIR%
wget -c http://zlib.net/zlib-%ZLIB_VER%.tar.gz -O zlib-%ZLIB_VER%.tar.gz
rm -rf "%DEPENDENCIES_BIN_DIR%\zlib
MKDIR "%DEPENDENCIES_BIN_DIR%\zlib
tar xf zlib-%ZLIB_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\zlib*
nmake -f win32/Makefile.msc || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\zlib\lib %DEPENDENCIES_BIN_DIR%\zlib\include
cp -v *.lib %DEPENDENCIES_BIN_DIR%\zlib\lib || GOTO :ERROR
cp -v *.dll %DEPENDENCIES_BIN_DIR%\zlib\lib || GOTO :ERROR
cp -v *.pdb %DEPENDENCIES_BIN_DIR%\zlib\lib || GOTO :ERROR
cp -v *.h %DEPENDENCIES_BIN_DIR%\zlib\include || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\zlib -y


:BUILD_UUID
CD %DOWNLOADS_DIR%
wget -c http://netcologne.dl.sourceforge.net/project/osspuuidwin32/src/ossp_uuid_1.6.2_win32_source_120608.7z -O ossp_uuid_1.6.2_win32_source_120608.7z
rm -rf %DEPENDENCIES_BIN_DIR%\uuid
MKDIR %DEPENDENCIES_BIN_DIR%\uuid
7z x %DOWNLOADS_DIR%\ossp_uuid_1.6.2_win32_source_120608.7z -o%DEPENDENCIES_SRC_DIR%\ -y || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\ossp_uuid
IF %ARCH% == X64 sed -i 's/Win32/x64/g' ossp_uuid.sln || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' ossp_uuid\ossp_uuid.vcxproj || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' example\example.vcxproj || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' uuid_cli\uuid_cli.vcxproj || GOTO :ERROR
IF %ARCH% == X64 msbuild ossp_uuid.sln /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X86 msbuild ossp_uuid.sln /p:Configuration=Release || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\uuid\lib
cp -av include %DEPENDENCIES_BIN_DIR%\uuid || GOTO :ERROR
IF %ARCH% == X64 cp -av x64\Release\ossp_uuid.lib %DEPENDENCIES_BIN_DIR%\uuid\lib\uuid.lib || GOTO :ERROR
IF %ARCH% == X86 cp -av Release\ossp_uuid.lib %DEPENDENCIES_BIN_DIR%\uuid\lib\uuid.lib || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\uuid -y


:BUILD_XML
CD %DOWNLOADS_DIR%
wget -c ftp://xmlsoft.org/libxml2/libxml2-%XML_VER%.tar.gz -O libxml2-%XML_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libxml2
MKDIR %DEPENDENCIES_BIN_DIR%\libxml2
tar xf libxml2-%XML_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\libxml2-*\win32
cscript configure.js compiler=msvc include=%DEPENDENCIES_BIN_DIR%\iconv\include lib=%DEPENDENCIES_BIN_DIR%\iconv\lib
sed -i /NOWIN98/d Makefile.msvc
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin %DEPENDENCIES_BIN_DIR%\libxml2 || GOTO :ERROR
cp -av lib %DEPENDENCIES_BIN_DIR%\libxml2 || GOTO :ERROR
cp -av include %DEPENDENCIES_BIN_DIR%\libxml2 || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\libxml2 -y


:BUILD_XSLT
CD %DOWNLOADS_DIR%
wget -c ftp://xmlsoft.org/libxslt/libxslt-%XSLT_VER%.tar.gz -O libxslt-%XSLT_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libxslt
MKDIR %DEPENDENCIES_BIN_DIR%\libxslt
tar xf libxslt-%XSLT_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\libxslt-*\win32
cscript configure.js compiler=msvc zlib=yes iconv=yes include=%DEPENDENCIES_BIN_DIR%\iconv\include;%DEPENDENCIES_BIN_DIR%\libxml2\include;%DEPENDENCIES_BIN_DIR%\zlib\include lib=%DEPENDENCIES_BIN_DIR%\iconv\lib;%DEPENDENCIES_BIN_DIR%\libxml2\lib;%DEPENDENCIES_BIN_DIR%\zlib\lib
sed -i /NOWIN98/d Makefile.msvc
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin %DEPENDENCIES_BIN_DIR%\libxslt || GOTO :ERROR
cp -av lib %DEPENDENCIES_BIN_DIR%\libxslt || GOTO :ERROR
cp -av include %DEPENDENCIES_BIN_DIR%\libxslt || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\libxslt -y


:BUILD_OPENSSL
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://www.openssl.org/source/openssl-%OPENSSL_VER%.tar.gz -O openssl-%OPENSSL_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\openssl
MKDIR %DEPENDENCIES_BIN_DIR%\openssl
tar xf openssl-%OPENSSL_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\openssl-*
IF %ARCH% == X86 perl Configure VC-WIN32 no-asm   || GOTO :ERROR
IF %ARCH% == X64 perl Configure VC-WIN64A no-asm  || GOTO :ERROR
IF %ARCH% == X86 call ms\do_ms
IF %ARCH% == X64 call ms\do_win64a.bat
nmake -f ms\ntdll.mak || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\openssl\lib
cp -av out32dll/* %DEPENDENCIES_BIN_DIR%\openssl\lib || GOTO :ERROR
cp -av include    %DEPENDENCIES_BIN_DIR%\openssl || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\openssl\lib\VC
cp -av out32dll/*           %DEPENDENCIES_BIN_DIR%\openssl\lib\VC || GOTO :ERROR
cp -v out32dll/ssleay32.lib %DEPENDENCIES_BIN_DIR%\openssl\lib\VC\ssleay32MD.lib || GOTO :ERROR
cp -v out32dll/libeay32.lib %DEPENDENCIES_BIN_DIR%\openssl\lib\VC\libeay32MD.lib || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\openssl -y


:BUILD_GETTEXT
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://ftp.gnu.org/gnu/gettext/gettext-%GETTEXT_VER%.tar.gz -O gettext-%GETTEXT_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libintl
MKDIR %DEPENDENCIES_BIN_DIR%\libintl
tar xf gettext-%GETTEXT_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD  %DEPENDENCIES_SRC_DIR%\gettext-*
cp -v %ROOT%/patches/gettext-%GETTEXT_VER%.patch .
patch -f -p0 < gettext-%GETTEXT_VER%.patch || GOTO :ERROR
IF %ARCH% == X64 msbuild libintl.vcxproj /p:Configuration=Release /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X86 msbuild libintl.vcxproj /p:Configuration=Release || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\libintl\lib %DEPENDENCIES_BIN_DIR%\libintl\include
cp -v Release*/*.dll  %DEPENDENCIES_BIN_DIR%\libintl\lib || GOTO :ERROR
cp -v Release*/*.lib  %DEPENDENCIES_BIN_DIR%\libintl\lib || GOTO :ERROR
cp -v libintl.h       %DEPENDENCIES_BIN_DIR%\libintl\include\libintl.h || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\libintl\bin
>%DEPENDENCIES_BIN_DIR%\libintl\bin\msgfmt.cmd ECHO msgfmt %%^*
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\libintl -y


:BUILD_LIBSSH2
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://www.libssh2.org/download/libssh2-%LIBSSH2_VER%.tar.gz -O libssh2-%LIBSSH2_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libssh2
MKDIR %DEPENDENCIES_BIN_DIR%\libssh2
tar xf libssh2-%LIBSSH2_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
cp -va %DEPENDENCIES_SRC_DIR%/libssh2-*/include %DEPENDENCIES_BIN_DIR%\libssh2\include  || GOTO :ERROR
cp -va %DEPENDENCIES_SRC_DIR%/libssh2-*/win32/libssh2_config.h %DEPENDENCIES_BIN_DIR%\libssh2\include  || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\libssh2 -y


:BUILD_WXWIDGETS
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://sourceforge.net/projects/wxwindows/files/%WXWIDGETS_VER%/wxWidgets-%WXWIDGETS_VER%.tar.bz2 -O wxWidgets-%WXWIDGETS_VER%.tar.bz2
rm -rf %DEPENDENCIES_BIN_DIR%\wxwidgets
MKDIR %DEPENDENCIES_BIN_DIR%\wxwidgets
tar xf wxWidgets-%WXWIDGETS_VER%.tar.bz2 -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD %DEPENDENCIES_SRC_DIR%\wxWidgets-*
IF %ARCH% == X86 msbuild build\msw\wx_vc10.sln  /p:Configuration="Release" || GOTO :ERROR
IF %ARCH% == X86 msbuild build\msw\wx_vc10.sln  /p:Configuration="DLL Release" || GOTO :ERROR
IF %ARCH% == X64 msbuild build\msw\wx_vc10.sln  /p:Configuration="Release" /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X64 msbuild build\msw\wx_vc10.sln  /p:Configuration="DLL Release" /p:Platform=x64 || GOTO :ERROR
cp -va %DEPENDENCIES_SRC_DIR%/wxWidgets-3*/lib      %DEPENDENCIES_BIN_DIR%\wxwidgets  || GOTO :ERROR
IF %ARCH% == X64 (
  mv -v %DEPENDENCIES_BIN_DIR%/wxwidgets/lib/vc_*dll   %DEPENDENCIES_BIN_DIR%\wxwidgets\lib\vc_dll  || GOTO :ERROR
  mv -v %DEPENDENCIES_BIN_DIR%/wxwidgets/lib/vc_*lib   %DEPENDENCIES_BIN_DIR%\wxwidgets\lib\vc_lib  || GOTO :ERROR
)
cp -va %DEPENDENCIES_SRC_DIR%/wxWidgets-3*/include  %DEPENDENCIES_BIN_DIR%\wxwidgets\include  || GOTO :ERROR
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\wxwidgets


:BUILD_ICU
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.zip -O icu4c-56_1-src.zip
rm -rf %DEPENDENCIES_BIN_DIR%\icu
MKDIR %DEPENDENCIES_BIN_DIR%\icu
7z x icu4c-56_1-src.zip -o%DEPENDENCIES_SRC_DIR% -y
CD %DEPENDENCIES_SRC_DIR%\icu
IF %ARCH% == X86 msbuild source\allinone\allinone.sln /p:Configuration="Release" || GOTO :ERROR
IF %ARCH% == X64 msbuild source\allinone\allinone.sln /p:Configuration="Release" /p:Platform=x64 || GOTO :ERROR
IF %ARCH% == X64 (
  cp -va %DEPENDENCIES_SRC_DIR%\icu\bin64 %DEPENDENCIES_BIN_DIR%\icu\bin || GOTO :ERROR
  cp -va %DEPENDENCIES_SRC_DIR%\icu\lib64 %DEPENDENCIES_BIN_DIR%\icu\lib || GOTO :ERROR
) ELSE (
  cp -va %DEPENDENCIES_SRC_DIR%\icu\bin %DEPENDENCIES_BIN_DIR%\icu\bin || GOTO :ERROR
  cp -va %DEPENDENCIES_SRC_DIR%\icu\lib %DEPENDENCIES_BIN_DIR%\icu\lib || GOTO :ERROR
)
cp -va %DEPENDENCIES_SRC_DIR%\icu\include %DEPENDENCIES_BIN_DIR%\icu\include || GOTO :ERROR
CD %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\icu


:BUILD_GEOS
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.osgeo.org/geos/geos-%GEOS_VER%.tar.bz2 -O geos-%GEOS_VER%.tar.bz2
tar xf geos-%GEOS_VER%.tar.bz2 -C %DEPENDENCIES_SRC_DIR%
CD %DEPENDENCIES_SRC_DIR%\geos-%GEOS_VER%
nmake -f makefile.vc || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\geos %DEPENDENCIES_BIN_DIR%\geos\lib %DEPENDENCIES_BIN_DIR%\geos\include
cp -va src/*.dll %DEPENDENCIES_BIN_DIR%\geos\lib || GOTO :ERROR
cp -va src/*.lib %DEPENDENCIES_BIN_DIR%\geos\lib || GOTO :ERROR
cp -va src/*.pdb %DEPENDENCIES_BIN_DIR%\geos\lib || GOTO :ERROR
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\geos


:BUILD_PROJ
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.osgeo.org/proj/proj-%PROJ_VER%.tar.gz -O proj-%PROJ_VER%.tar.gz
tar xf proj-%PROJ_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR%
CD %DEPENDENCIES_SRC_DIR%\proj-%PROJ_VER%
nmake -f makefile.vc || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\proj %DEPENDENCIES_BIN_DIR%\proj\lib %DEPENDENCIES_BIN_DIR%\proj\include
cp -va src/*.dll %DEPENDENCIES_BIN_DIR%\proj\lib || GOTO :ERROR
cp -va src/*.lib %DEPENDENCIES_BIN_DIR%\proj\lib || GOTO :ERROR
cp -va src/*.pdb %DEPENDENCIES_BIN_DIR%\proj\lib || GOTO :ERROR
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\proj


:BUILD_GDAL
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.osgeo.org/gdal/gdal-%GDAL_VER%.tar.gz -O gdal-%GDAL_VER%.tar.gz
tar xf gdal-%GDAL_VER%.tar.gz -C %DEPENDENCIES_SRC_DIR%
CD %DEPENDENCIES_SRC_DIR%\gdal-%GDAL_VER%
IF %ARCH% == X86 nmake -f makefile.vc MSVC_VER=1600 || GOTO :ERROR
IF %ARCH% == X64 nmake -f makefile.vc MSVC_VER=1600 WIN64=YES || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\gdal %DEPENDENCIES_BIN_DIR%\gdal\lib %DEPENDENCIES_BIN_DIR%\gdal\include
cp -va *.dll %DEPENDENCIES_BIN_DIR%\gdal\lib || GOTO :ERROR
cp -va *.lib %DEPENDENCIES_BIN_DIR%\gdal\lib || GOTO :ERROR
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\gdal


:BUILD_JSONC
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://github.com/json-c/json-c/archive/%JSONC_VER%.zip -O json-c-%JSONC_VER%.zip
7z x json-c-%JSONC_VER%.zip -o%DEPENDENCIES_SRC_DIR%
CD %DEPENDENCIES_SRC_DIR%\json-c-%JSONC_VER%
patch -f -p1 -V existing < c:\pgwininstall\patches\json-c.patch
cp c:/pg/json-c.vcxproj .
IF %ARCH% == X86 msbuild json-c.vcxproj /p:Configuration="Release"
IF %ARCH% == X64 msbuild json-c.vcxproj /p:Configuration="Release" /p:Platform=x64
MKDIR %DEPENDENCIES_BIN_DIR%\json-c %DEPENDENCIES_BIN_DIR%\json-c\lib %DEPENDENCIES_BIN_DIR%\json-c\include
IF %ARCH% == X64 cp -va x64/Release/*.dll   %DEPENDENCIES_BIN_DIR%\json-c\lib || GOTO :ERROR
IF %ARCH% == X86 cp -va win32/Release/*.dll %DEPENDENCIES_BIN_DIR%\json-c\lib || GOTO :ERROR
cp -va *.h %DEPENDENCIES_BIN_DIR%\json-c\include
7z a -r %DOWNLOADS_DIR%\deps_%ARCH%.zip %DEPENDENCIES_BIN_DIR%\json-c

REM If everything is compiled OK go to DONE
GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
