echo.
echo Building Installer...


>Files.wxs  ECHO ^<^?xml version="1.0" encoding="UTF-8"?^>
>>Files.wxs  ECHO ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
>>Files.wxs  ECHO ^<^?include Variables.wxi?^>
>>Files.wxs  ECHO ^<Fragment^>
>>Files.wxs  ECHO ^<DirectoryRef Id = "INSTALLLOCATION"^>
>>Files.wxs  ECHO 	^<^Directory Id="BIN" Name="bin"^>
>>Files.wxs  ECHO     		^<^Component Id="ProductComponent" Guid="$(var.ComponentCode)" Win64="$(var.Win64)"^>
perl genfilelist.pl ./out/bin/*.* Files.wxs
>>Files.wxs  ECHO 		^<^/Component^>
>>Files.wxs  ECHO 	^<^/Directory^>
>>Files.wxs  ECHO ^<^/DirectoryRef^>
>>Files.wxs  ECHO ^<^/Fragment^>
>>Files.wxs  ECHO ^<^/Wix^>

SET WIXDIR=C:\Program Files (x86)\WiX Toolset v3.11\bin
perl regenguids.pl Variables.wxi
move Variables.wxi.out Variables.wxi
echo on
"%WIXDIR%\candle" -nologo  -dAPPVERSION="%APPVERSION%" -dPG_REG_KEY="%PG_REG_KEY%" -dPG_DEF_BRANDING="%PG_DEF_BRANDING%" Product.wxs Files.wxs || goto :ERROR
                                                                                                      
rem SET INS_FILE=pg-probackup-%EDITION%-%PG_MAJOR_VERSION%-%APPVERSION%-%BITS%.msi
SET INS_FILE=pg-probackup-%EDITION%-%PG_MAJOR_VERSION%-%APPVERSION%.msi

"%WIXDIR%\light" -sice:ICE03 -sice:ICE25 -sice:ICE82 -sw1101 -nologo -ext WixUIExtension -cultures:ru-ru -o %INS_FILE% Files.wixobj Product.wixobj || goto :ERROR

echo.
echo Building Full Installer...

>Files.wxs  ECHO ^<^?xml version="1.0" encoding="UTF-8"?^>
>>Files.wxs  ECHO ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
>>Files.wxs  ECHO ^<^?include Variables.wxi?^>
>>Files.wxs  ECHO ^<Fragment^>
>>Files.wxs  ECHO ^<DirectoryRef Id = "INSTALLLOCATION"^>
>>Files.wxs  ECHO     		^<^Component Id="ProductComponent" Guid="$(var.ComponentCode)" Win64="$(var.Win64)"^>
perl genfilelist.pl ./out_full/*.* Files.wxs
>>Files.wxs  ECHO 		^<^/Component^>
>>Files.wxs  ECHO ^<^/DirectoryRef^>
>>Files.wxs  ECHO ^<^/Fragment^>
>>Files.wxs  ECHO ^<^/Wix^>
"%WIXDIR%\candle" -nologo  -dAPPVERSION="%APPVERSION%" -dPG_REG_KEY="%PG_REG_KEY%" -dPG_DEF_BRANDING="%PG_DEF_BRANDING%" Product_separate.wxs Files.wxs || goto :ERROR
                                                                                                      
rem SET INS_FILE=pg-probackup-%EDITION%-%PG_MAJOR_VERSION%-%APPVERSION%-%BITS%-standalone.msi
SET INS_FILE=pg-probackup-%EDITION%-%PG_MAJOR_VERSION%-%APPVERSION%-standalone-en.msi

"%WIXDIR%\light" -sice:ICE03 -sice:ICE25 -sice:ICE82 -sw1101 -nologo -ext WixUIExtension -cultures:en-us -o %INS_FILE% Files.wixobj Product_separate.wixobj || goto :ERROR

SET INS_FILE=pg-probackup-%EDITION%-%PG_MAJOR_VERSION%-%APPVERSION%-standalone-ru.msi

"%WIXDIR%\light" -sice:ICE03 -sice:ICE25 -sice:ICE82 -sw1101 -nologo -ext WixUIExtension -cultures:ru-ru -o %INS_FILE% Files.wixobj Product_separate.wixobj || goto :ERROR


goto :DONE


:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
