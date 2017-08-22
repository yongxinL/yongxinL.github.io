@echo off
:: Run as administrator 
:: Modify the following content, define the selection you want to use the KMS server. If you define the times, the last valid 

set KMS_Sev=usalwdc6.infor.com:1688
set KMS_Sev=10.61.30.5:1688

::======================= The following do NOT need to change ====================== 
:: Check Windows Version
:: please refer to Microsoft article for full list of Windows version
:: https://msdn.microsoft.com/en-us/library/ms724832(VS.85).aspx
:: 5.0 = W2K
:: 5.1 = XP
:: 5.2 = Server 2003
:: 6.0 = Vista or Server 2008
:: 6.1 = 7 or Server 2008 r2
:: 6.2 = 8 or Server 2012
:: 6.3 = 8.1 or Server 2012 r2
:: 10.0 = 10 or Server 2016

echo Detecting platform ...
set platform=W
net accounts | find "WORKSTATION" >nul
if errorlevel 1 set platform=S

echo Detecting OS version ...
for /f "tokens=4-7 delims=[.] " %%i in ('ver') do set VERSION=%%i_%%j_%platform%
:: Server 2016
if "%version%" == "10_0_S" (
	set KMS_Key=WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
)
:: Windows 10
if "%version%" == "10_0_W" (
	set KMS_Key=NPPR9-FWDCX-D2C8J-H872K-2YT43
)
:: Server 2012 r2
if "%version%" == "6_3_S" (
	set KMS_Key=D2N9P-3P6X9-2R39C-7RTCD-MDVJX
)
:: Windows 8.1
if "%version%" == "6_3_W" (
	set KMS_Key=MHF9N-XY6XB-WVXMC-BTDCT-MKKG7
)
:: Server 2012
if "%version%" == "6_2_S" (
	set KMS_Key=XC9B7-NBPP2-83J2H-RHMBY-92BT4
)
:: Windows 8
if "%version%" == "6_2_W" (
	set KMS_Key=32JNW-9KQ84-P47T8-D8GGY-CWCK7
)
:: Server 2008 r2
if "%version%" == "6_1_S" (
	set KMS_Key=YC6KT-GKW9T-YTKYR-T4X34-R7VHC
)
:: Server 2008
if "%version%" == "6_0_S" (
	set KMS_Key=TM24T-X9RMF-VWXK6-X8JC9-BFGM2
)

:: Windows Activation
setlocal EnableDelayedExpansion&color 3e & cd /d "%~dp0" 
title Windows %version% KMS Activation

if exist "%SystemRoot%\System32\slmgr.vbs" cd /d "%SystemRoot%\System32"

echo Importing KMS Key ...
cscript //nologo slmgr.vbs /ipk %KMS_Key%

echo Trying KMS Activation... 
cscript //nologo slmgr.vbs /skms %KMS_Sev% >nul
cscript //nologo slmgr.vbs /ato | find /i "successful" && ( 
          echo.&echo ***** Windows %version% Activation successful ***** & echo.) || (echo.&echo ***** Windows %version% Activation fails ***** & echo. 
          echo Please check the network connection, and select Modify other KMS server and try again) 
pause