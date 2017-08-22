@echo off
:: Run as administrator 
::
:: System Preparation (Sysprep) tool prepares an installation of Windows for imaging
::

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

:: unattend file
set unattend=unattend_%VERSION%

::======================= The following do NOT need to change ====================== 
setlocal EnableDelayedExpansion&color 3e & cd /d "%~dp0" 
title Windows %version% preparation

echo Preparing system before generalizing image ...

:: reset Quick access to defaults
echo Y | del "%APPDATA%\Microsoft\Windows\Recent\Automaticdestinations\*"

:: disable IE suggested sites
reg import "%SystemRoot%\System\sysprep\DisableSuggestedSites.reg"

:: place RunOnce.cmd into administrator StartUp
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" md "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "%SystemRoot%\System\sysprep\RunOnce.cmd" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RunOnce.cmd"

:: cleanup temporary and WinSxS remove all superseded component version (WinSxS)
echo Y | del "%LOCALAPPDATA%\Temp\*" /q/s
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

:: execute sysprep tool
echo Trying System Preparation ...
cmd /c %SystemRoot%\System32\Sysprep\sysprep.exe /oobe /generalize /quit /unattend:"%SystemRoot%\System\sysprep\%unattend%.xml"

:: system turnning
call c:\windows\system\SystemTunning.cmd

pause