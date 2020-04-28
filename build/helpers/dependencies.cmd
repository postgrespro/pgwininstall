CALL %ROOT%\build\helpers\setvars.cmd

REM GOTO LAST BUILD
GOTO :BUILD_ALL

:BUILD_ALL
MKDIR %BUILD_DIR%
MKDIR %DEPENDENCIES_BIN_DIR%
rm -rf %DEPENDENCIES_SRC_DIR%
MKDIR %DEPENDENCIES_SRC_DIR%
MKDIR %DOWNLOADS_DIR%

IF %SDK% == MSVC2015 (
SET WindowsTargetPlatformVersion=%WindowsSDKVersion%
)
IF %SDK% == MSVC2017 (
SET WindowsTargetPlatformVersion=%WindowsSDKVersion%
)
IF %SDK% == MSVC2019 (
SET WindowsTargetPlatformVersion=%WindowsSDKVersion%
)

rem GOTO :BUILD_ICONV

if "%PRODUCT_NAME%" == "PostgreSQL"  goto :SKIP_ZSTD
if "%PRODUCT_NAME%" == "PostgresPro" goto :SKIP_ZSTD


:ZSTD
TITLE "Building libzstd"
IF "ZSTD_RELEASE" == "" set ZSTD_RELEASE=1.1.0
CD /D %DOWNLOADS_DIR%
wget -O zstd-%ZSTD_RELEASE%.zip --no-check-certificate -c https://github.com/facebook/zstd/archive/v%ZSTD_RELEASE%.zip
rm -rf %DEPENDENCIES_SRC_DIR%/zstd-%ZSTD_RELEASE%
MKDIR %DEPENDENCIES_SRC_DIR%\zstd-%ZSTD_RELEASE%
CD /D %DEPENDENCIES_SRC_DIR%
7z x %DOWNLOADS_DIR%\zstd-%ZSTD_RELEASE%.zip
CD zstd-%ZSTD_RELEASE%

IF %SDK% == MSVC2017 (
CD build/VS2010
msbuild zstd.sln /m /p:Configuration=Release /p:Platform=%Platform% /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
CD ../..
GOTO :ENDZSTD
)

IF %SDK% == MSVC2019 (
CD build/VS2010
rem call "./../VS_Scripts/build.VS%REDIST_YEAR%.cmd" || GOTO :ERROR
rem call "./../VS_Scripts/build.generic.cmd" VS2017 x64 Release v141 || GOTO :ERROR
msbuild zstd.sln /m /p:Configuration=Release /p:Platform=%Platform% /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
CD ../..
GOTO :ENDZSTD
)
call build/VS_Scripts/build.VS%REDIST_YEAR%.cmd || GOTO :ERROR

:ENDZSTD
MKDIR %DEPENDENCIES_BIN_DIR%\zstd
cp lib\zstd.h %DEPENDENCIES_BIN_DIR%\zstd
if %ARCH% == X86 (
	cp -va build/VS_Scripts/BIN/Release/Win32/zstdlib_x86* %DEPENDENCIES_BIN_DIR%\zstd
) else (
	cp -va build/VS_Scripts/BIN/Release/x64/zstdlib_x64* %DEPENDENCIES_BIN_DIR%\zstd
	cp -va build/VS2010/bin/x64_Release/libzstd* %DEPENDENCIES_BIN_DIR%\zstd
	cp -va build/VS2010/bin/x64/Release/zstdlib_x64* %DEPENDENCIES_BIN_DIR%\zstd
)
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\zstd

:SKIP_ZSTD

REM TO-DO: overwrite to build rules
:DOWNLOAD_MSYS_UTILS
TITLE Download msys utils...
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate -c http://repo.l.postgrespro.ru/depends/mingw_min/min_msys_X86.zip -O min_msys_%ARCH%.zip

:BUILD_LESS
TITLE "Building less"
CD /D %DOWNLOADS_DIR%
wget -O less.zip --no-check-certificate -c https://github.com/vbwagner/less/archive/master.zip
rm -rf %DEPENDENCIES_SRC_DIR%\less-master %DEPENDENCIES_BIN_DIR%\less
MKDIR %DEPENDENCIES_SRC_DIR%\less-master
CD /D %DEPENDENCIES_SRC_DIR%
7z x %DOWNLOADS_DIR%\less.zip


CD /D %DEPENDENCIES_SRC_DIR%\less-master
IF %ARCH% == X86 (
   nmake -f Makefile.wnm || GOTO :ERROR
) ELSE (
   nmake -f Makefile.wnm ARCH=%ARCH%|| GOTO :ERROR
)
MKDIR %DEPENDENCIES_BIN_DIR%\less
cp -va *.exe %DEPENDENCIES_BIN_DIR%\less

7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\less

:BUILD_WINLIBEDIT
TITLE Build winlibedit
CD /D %DOWNLOADS_DIR%
REM wget --no-check-certificate -c http://downloads.sourceforge.net/project/mingweditline/wineditline-%EDITLINE_VER%.zip
wget --no-check-certificate -c http://repo.l.postgrespro.ru/depends/wineditline-%EDITLINE_VER%.zip
CD /D %DEPENDENCIES_SRC_DIR%
7z x %DOWNLOADS_DIR%\wineditline-%EDITLINE_VER%.zip
CD /D wineditline-%EDITLINE_VER%\src
patch -p2 < %ROOT%/patches/wineditline/clipboard_paste.patch || goto :ERROR
CL -I. /MD -c history.c editline.c fn_complete.c || goto :ERROR
LIB /out:edit.lib *.obj || goto :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\wineditline
MKDIR %DEPENDENCIES_BIN_DIR%\wineditline\include 
MKDIR %DEPENDENCIES_BIN_DIR%\wineditline\include\editline
if %ARCH% == X64 (
   MKDIR %DEPENDENCIES_BIN_DIR%\wineditline\lib64
   COPY edit.lib %DEPENDENCIES_BIN_DIR%\wineditline\lib64
) else (
   MKDIR %DEPENDENCIES_BIN_DIR%\wineditline\lib32
   COPY edit.lib %DEPENDENCIES_BIN_DIR%\wineditline\lib32
)
COPY editline\readline.h %DEPENDENCIES_BIN_DIR%\wineditline\include\editline

7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\wineditline

:BUILD_ICONV
TITLE Building iconv...
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate -c http://ftp.gnu.org/gnu/libiconv/libiconv-%ICONV_VER%.tar.gz -O libiconv-%ICONV_VER%.tar.gz
rem wget --no-check-certificate -c http://repo.l.postgrespro.ru/depends/libiconv-%ICONV_VER%.tar.gz -O libiconv-%ICONV_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\iconv %DEPENDENCIES_SRC_DIR%\libiconv-*
MKDIR %DEPENDENCIES_BIN_DIR%\iconv
tar xf libiconv-%ICONV_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR% || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\libiconv-%ICONV_VER%*
cp -v %ROOT%/patches/libiconv/libiconv-%ICONV_VER%-%SDK%.patch libiconv.patch

patch -f -p0 < libiconv.patch || GOTO :ERROR

msbuild libiconv.vcxproj /m /p:Configuration=Release /p:Platform=%Platform%  /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR

cp -av include %DEPENDENCIES_BIN_DIR%\iconv || GOTO :ERROR
cp -av iconv.h %DEPENDENCIES_BIN_DIR%\iconv\include || GOTO :ERROR
cp -av config.h %DEPENDENCIES_BIN_DIR%\iconv\include || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\iconv\lib
cp -av Release*/*.dll %DEPENDENCIES_BIN_DIR%\iconv\lib || GOTO :ERROR
cp -av Release*/libiconv.dll %DEPENDENCIES_BIN_DIR%\iconv\lib\iconv.dll || GOTO :ERROR
cp -av Release*/*.lib %DEPENDENCIES_BIN_DIR%\iconv\lib || GOTO :ERROR
cp -av Release*/libiconv.lib %DEPENDENCIES_BIN_DIR%\iconv\lib\iconv.lib || GOTO :ERROR
cp -av lib %DEPENDENCIES_BIN_DIR%\iconv\libiconv || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\iconv


:BUILD_ZLIB
TITLE Building zlib...
CD /D %DOWNLOADS_DIR%
wget -c http://zlib.net/zlib-%ZLIB_VER%.tar.gz -O zlib-%ZLIB_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\zlib %DEPENDENCIES_SRC_DIR%\zlib*
MKDIR %DEPENDENCIES_BIN_DIR%\zlib
tar xf zlib-%ZLIB_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR% || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\zlib*
set CL=/MP
nmake -f win32/Makefile.msc || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\zlib\lib %DEPENDENCIES_BIN_DIR%\zlib\include
cp -v *.lib %DEPENDENCIES_BIN_DIR%\zlib\lib || GOTO :ERROR
cp -v *.dll %DEPENDENCIES_BIN_DIR%\zlib\lib || GOTO :ERROR
cp -v *.pdb %DEPENDENCIES_BIN_DIR%\zlib\lib || GOTO :ERROR
cp -v *.h %DEPENDENCIES_BIN_DIR%\zlib\include || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\zlib -y


:BUILD_UUID
TITLE Building uuid...
CD /D %DOWNLOADS_DIR%
wget -c http://netcologne.dl.sourceforge.net/project/osspuuidwin32/src/ossp_uuid_1.6.2_win32_source_120608.7z -O ossp_uuid_1.6.2_win32_source_120608.7z
rm -rf %DEPENDENCIES_BIN_DIR%\uuid %DEPENDENCIES_SRC_DIR%\ossp_uuid
MKDIR %DEPENDENCIES_BIN_DIR%\uuid
7z x %DOWNLOADS_DIR%\ossp_uuid_1.6.2_win32_source_120608.7z -o%DEPENDENCIES_SRC_DIR%\ -y || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\ossp_uuid
patch -p1 < %ROOT%/patches/uuid/oosp_uuid.patch || goto :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' ossp_uuid.sln || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' ossp_uuid\ossp_uuid.vcxproj || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' example\example.vcxproj || GOTO :ERROR
IF %ARCH% == X64 sed -i 's/Win32/x64/g' uuid_cli\uuid_cli.vcxproj || GOTO :ERROR
msbuild ossp_uuid.sln /m /p:Configuration=Release /p:Platform=%Platform% /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\uuid\lib
cp -av include %DEPENDENCIES_BIN_DIR%\uuid || GOTO :ERROR
IF %ARCH% == X64 cp -av x64\Release\ossp_uuid.lib %DEPENDENCIES_BIN_DIR%\uuid\lib\uuid.lib || GOTO :ERROR
IF %ARCH% == X86 cp -av Release\ossp_uuid.lib %DEPENDENCIES_BIN_DIR%\uuid\lib\uuid.lib || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\uuid -y


:BUILD_XML
TITLE Building xml...
CD /D %DOWNLOADS_DIR%
REM wget -c ftp://xmlsoft.org/libxml2/libxml2-%XML_VER%.tar.gz -O libxml2-%XML_VER%.tar.gz
wget -c http://repo.postgrespro.ru/depends/libxml2-%XML_VER%.tar.gz -O libxml2-%XML_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libxml2 %DEPENDENCIES_SRC_DIR%\libxml2-*
MKDIR %DEPENDENCIES_BIN_DIR%\libxml2
tar xf libxml2-%XML_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR% || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\libxml2-*
rem libxml2 2.9.7 doesn't need this patch
rem patch -f -p1 < %ROOT%/patches/libxml2/libxml2.patch || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\libxml2-*\win32
cscript configure.js compiler=msvc include=%DEPENDENCIES_BIN_DIR%\iconv\include lib=%DEPENDENCIES_BIN_DIR%\iconv\lib
sed -i /NOWIN98/d Makefile.msvc
set CL=/MP
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
rem "override old libxml2.dll location with freshly build dll"
cp bin\libxml2.dll lib || GOTO :ERROR
cp -av bin %DEPENDENCIES_BIN_DIR%\libxml2 || GOTO :ERROR
cp -av lib %DEPENDENCIES_BIN_DIR%\libxml2 || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\libxml2\include || GOTO :ERROR
cp -av include\libxml2\libxml %DEPENDENCIES_BIN_DIR%\libxml2\include || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\libxml2 -y


:BUILD_XSLT
TITLE Building xslt...
CD /D %DOWNLOADS_DIR%
REM wget -c ftp://xmlsoft.org/libxslt/libxslt-%XSLT_VER%.tar.gz -O libxslt-%XSLT_VER%.tar.gz
wget -c http://repo.postgrespro.ru/depends/libxslt-%XSLT_VER%.tar.gz -O libxslt-%XSLT_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libxslt %DEPENDENCIES_SRC_DIR%\libxslt-*
MKDIR %DEPENDENCIES_BIN_DIR%\libxslt
tar xf libxslt-%XSLT_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR% || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\libxslt-*\win32
cscript configure.js compiler=msvc zlib=yes iconv=yes include=%DEPENDENCIES_BIN_DIR%\iconv\include;%DEPENDENCIES_BIN_DIR%\libxml2\include;%DEPENDENCIES_BIN_DIR%\zlib\include lib=%DEPENDENCIES_BIN_DIR%\iconv\lib;%DEPENDENCIES_BIN_DIR%\libxml2\lib;%DEPENDENCIES_BIN_DIR%\zlib\lib
sed -i /NOWIN98/d Makefile.msvc
set CL=/MP
nmake /f Makefile.msvc || GOTO :ERROR
nmake /f Makefile.msvc install || GOTO :ERROR
cp -av bin %DEPENDENCIES_BIN_DIR%\libxslt || GOTO :ERROR
cp -av lib %DEPENDENCIES_BIN_DIR%\libxslt || GOTO :ERROR
cp -av include %DEPENDENCIES_BIN_DIR%\libxslt || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\libxslt -y


:BUILD_OPENSSL
TITLE Building OpenSSL...
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate -c https://www.openssl.org/source/openssl-%OPENSSL_VER%.tar.gz -O openssl-%OPENSSL_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\openssl %DEPENDENCIES_SRC_DIR%\openssl-*
MKDIR %DEPENDENCIES_BIN_DIR%\openssl
tar zxf openssl-%OPENSSL_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR%
CD /D %DEPENDENCIES_SRC_DIR%\openssl-*
IF %ARCH% == X86 perl Configure VC-WIN32 no-asm   || GOTO :ERROR
IF %ARCH% == X64 perl Configure VC-WIN64A no-asm  || GOTO :ERROR
IF %ARCH% == X86 call ms\do_ms
IF %ARCH% == X64 call ms\do_win64a.bat
set CL=/MP
nmake -f ms\ntdll.mak || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\openssl\lib
MKDIR %DEPENDENCIES_BIN_DIR%\openssl\include
cp -av out32dll/* %DEPENDENCIES_BIN_DIR%\openssl\lib || GOTO :ERROR
cp -av inc32/*    %DEPENDENCIES_BIN_DIR%\openssl\include || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\openssl\lib\VC
cp -av out32dll/*           %DEPENDENCIES_BIN_DIR%\openssl\lib\VC || GOTO :ERROR
cp -v out32dll/ssleay32.lib %DEPENDENCIES_BIN_DIR%\openssl\lib\VC\ssleay32MD.lib || GOTO :ERROR
cp -v out32dll/libeay32.lib %DEPENDENCIES_BIN_DIR%\openssl\lib\VC\libeay32MD.lib || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\openssl\bin
cp -av out32dll/openssl.exe %DEPENDENCIES_BIN_DIR%\openssl\bin || GOTO :ERROR
cp -av out32dll/*32.dll %DEPENDENCIES_BIN_DIR%\openssl\bin || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\openssl -y


:BUILD_GETTEXT
TITLE Building gettext...
CD /D %DOWNLOADS_DIR%
REM wget --no-check-certificate -c http://ftp.gnu.org/gnu/gettext/gettext-%GETTEXT_VER%.tar.gz -O gettext-%GETTEXT_VER%.tar.gz
wget --no-check-certificate -c http://repo.l.postgrespro.ru/depends/gettext-%GETTEXT_VER%.tar.gz -O gettext-%GETTEXT_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_DIR%\libintl %DEPENDENCIES_SRC_DIR%\gettext-*
MKDIR %DEPENDENCIES_BIN_DIR%\libintl
tar xf gettext-%GETTEXT_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR% || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\gettext-*
cp -v %ROOT%/patches/gettext/gettext-%GETTEXT_VER%-%SDK%.patch gettext.patch
patch -f -p0 < gettext.patch || GOTO :ERROR
msbuild libintl.vcxproj /m /p:Configuration=Release /p:Platform=%Platform% /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\libintl\lib %DEPENDENCIES_BIN_DIR%\libintl\include
cp -v Release*/*.dll  %DEPENDENCIES_BIN_DIR%\libintl\lib || GOTO :ERROR
cp -v Release*/*.lib  %DEPENDENCIES_BIN_DIR%\libintl\lib || GOTO :ERROR
cp -v libintl.h       %DEPENDENCIES_BIN_DIR%\libintl\include\libintl.h || GOTO :ERROR
MKDIR %DEPENDENCIES_BIN_DIR%\libintl\bin
>%DEPENDENCIES_BIN_DIR%\libintl\bin\msgfmt.cmd ECHO msgfmt %%^*
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\libintl -y


:BUILD_LIBSSH2
TITLE Building libssh2...
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate -c http://www.libssh2.org/download/libssh2-%LIBSSH2_VER%.tar.gz -O libssh2-%LIBSSH2_VER%.tar.gz
rm -rf %DEPENDENCIES_BIN_UDIR%/libssh2 %DEPENDENCIES_SRC_UDIR%/libssh2-*
MKDIR %DEPENDENCIES_BIN_DIR%\libssh2
tar xf libssh2-%LIBSSH2_VER%.tar.gz -C %DEPENDENCIES_SRC_UDIR% || GOTO :ERROR
cp -va %DEPENDENCIES_SRC_UDIR%/libssh2-*/include %DEPENDENCIES_BIN_UDIR%/libssh2/include  || GOTO :ERROR
cp -va %DEPENDENCIES_SRC_UDIR%/libssh2-*/win32/libssh2_config.h %DEPENDENCIES_BIN_UDIR%/libssh2/include  || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\libssh2 -y


:BUILD_ICU
TITLE Building icu...
CD /D %DOWNLOADS_DIR%
rem wget --no-check-certificate -c http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.zip -O icu4c-56_1-src.zip
wget --no-check-certificate -c https://github.com/unicode-org/icu/releases/download/release-56-2/icu4c-56_2-src.zip -O icu4c-56_2-src.zip
rm -rf %DEPENDENCIES_BIN_DIR%\icu %DEPENDENCIES_SRC_DIR%\icu
MKDIR %DEPENDENCIES_BIN_DIR%\icu
7z x icu4c-56_2-src.zip -o%DEPENDENCIES_SRC_DIR% -y
CD /D %DEPENDENCIES_SRC_DIR%\icu
msbuild source\allinone\allinone.sln /m /p:Configuration="Release" /p:Platform=%Platform% /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
IF %ARCH% == X64 (
  cp -va %DEPENDENCIES_SRC_DIR%\icu\bin64 %DEPENDENCIES_BIN_DIR%\icu\bin || GOTO :ERROR
  cp -va %DEPENDENCIES_SRC_DIR%\icu\lib64 %DEPENDENCIES_BIN_DIR%\icu\lib || GOTO :ERROR
  cp -va %DEPENDENCIES_SRC_DIR%\icu\lib64 %DEPENDENCIES_BIN_DIR%\icu\lib64 || GOTO :ERROR
) ELSE (
  cp -va %DEPENDENCIES_SRC_DIR%\icu\bin %DEPENDENCIES_BIN_DIR%\icu\bin || GOTO :ERROR
  cp -va %DEPENDENCIES_SRC_DIR%\icu\lib %DEPENDENCIES_BIN_DIR%\icu\lib || GOTO :ERROR
)
cp -va %DEPENDENCIES_SRC_DIR%\icu\include %DEPENDENCIES_BIN_DIR%\icu\include || GOTO :ERROR
CD /D %DOWNLOADS_DIR%
7z a -r %DOWNLOADS_DIR%\%DEPS_ZIP% %DEPENDENCIES_BIN_DIR%\icu

REM If everything is compiled OK go to DONE
GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
