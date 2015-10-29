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

REM LIBRARIES
SET GEOS_VER=3.4.2
SET PROJ_VER=4.6.1
SET GDAL_VER=1.6.3
SET JSONC_VER=1757a31750134577faf80b91d0cf6f98d3918e6c

REM GO TO LAST BUILD
GOTO :BUILD_ALL

:BUILD_ALL

IF EXIST %DOWNLOADS_DIR%\deps_%ARCH%.zip (
  7z x %DOWNLOADS_DIR%\deps_%ARCH%.zip -o%DEPENDENCIES_DIR%
) ELSE (
  ECHO "You need to build dependencies first!"
  GOTO :ERROR
)

:BUILD_GEOS
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.osgeo.org/geos/geos-%GEOS_VER%.tar.bz2 -O geos-%GEOS_VER%.tar.bz2 
tar xf geos-%GEOS_VER%.tar.bz2 -C %DOWNLOADS_DIR%
CD %DOWNLOADS_DIR%\geos-%GEOS_VER%
nmake -f makefile.vc || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\geos %DEPENDENCIES_DIR%\geos\lib %DEPENDENCIES_DIR%\geos\include
cp -va src/*.dll %DEPENDENCIES_DIR%\geos\lib || GOTO :ERROR
cp -va src/*.lib %DEPENDENCIES_DIR%\geos\lib || GOTO :ERROR
cp -va src/*.pdb %DEPENDENCIES_DIR%\geos\lib || GOTO :ERROR

:BUILD_PROJ
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.osgeo.org/proj/proj-%PROJ_VER%.tar.gz -O proj-%PROJ_VER%.tar.gz
tar xf proj-%PROJ_VER%.tar.gz -C %DOWNLOADS_DIR%
CD %DOWNLOADS_DIR%\proj-%PROJ_VER%
nmake -f makefile.vc || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\proj %DEPENDENCIES_DIR%\proj\lib %DEPENDENCIES_DIR%\proj\include
cp -va src/*.dll %DEPENDENCIES_DIR%\proj\lib || GOTO :ERROR
cp -va src/*.lib %DEPENDENCIES_DIR%\proj\lib || GOTO :ERROR
cp -va src/*.pdb %DEPENDENCIES_DIR%\proj\lib || GOTO :ERROR

:BUILD_GDAL
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c http://download.osgeo.org/gdal/gdal-%GDAL_VER%.tar.gz -O gdal-%GDAL_VER%.tar.gz
tar xf gdal-%GDAL_VER%.tar.gz -C %DOWNLOADS_DIR%
CD %DOWNLOADS_DIR%\gdal-%GDAL_VER%
IF %ARCH% == X86 nmake -f makefile.vc MSVC_VER=1600 || GOTO :ERROR
IF %ARCH% == X64 nmake -f makefile.vc MSVC_VER=1600 WIN64=YES || GOTO :ERROR
MKDIR %DEPENDENCIES_DIR%\gdal %DEPENDENCIES_DIR%\gdal\lib %DEPENDENCIES_DIR%\gdal\include
cp -va *.dll %DEPENDENCIES_DIR%\gdal\lib || GOTO :ERROR
cp -va *.lib %DEPENDENCIES_DIR%\gdal\lib || GOTO :ERROR

:BUILD_JSONC
CD %DOWNLOADS_DIR%
wget --no-check-certificate -c https://github.com/json-c/json-c/archive/%JSONC_VER%.zip -O json-c-%JSONC_VER%.zip
7z x json-c-%JSONC_VER%.zip -o%DOWNLOADS_DIR%
CD json-c-%JSONC_VER%
patch -p1 -V existing < c:\pgwininstall\patches\json-c.patch
cp c:/pg/json-c.vcxproj .
IF %ARCH% == X86 msbuild json-c.vcxproj /p:Configuration="Release"
IF %ARCH% == X64 msbuild json-c.vcxproj /p:Configuration="Release" /p:Platform=x64
MKDIR %DEPENDENCIES_DIR%\json-c %DEPENDENCIES_DIR%\json-c\lib %DEPENDENCIES_DIR%\jcon-c\include
IF %ARCH% == X64 cp -va x64/Release/*.dll %DEPENDENCIES_DIR%\json-c\lib || GOTO :ERROR
IF %ARCH% == X86 cp -va win32/Release/*.dll %DEPENDENCIES_DIR%\json-c\lib || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
rm -rf %DEPENDENCIES_DIR%/*
ECHO Done.
PAUSE
