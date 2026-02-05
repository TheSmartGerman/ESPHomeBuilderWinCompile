 @echo off
title ESPHome Win Compile
rem https://community.home-assistant.io/t/compile-esphome-firmware-updates-on-a-windows-computer/675385

rem run this only once to get parameters for drag and drop
rem https://stackoverflow.com/questions/1243240/drag-and-drop-batch-file-for-multiple-files
setlocal ENABLEDELAYEDEXPANSION
rem Take the cmd-line, remove all until the first parameter
echo Gathering files to compile...
set "params=!cmdcmdline:~0,-1!"
set "params=!params:*" =!"
echo Files: %params%

:startup
rem read ip settings
echo Gathering settings:
echo Read IP Address...
if not exist %TMP%\ip.tmp (
  set hassip=192.168.178.100
) else (
  for /f "usebackq delims=" %%A in (%TMP%\ip.tmp) do set "hassip=%%A"
)

rem read esphome local version
echo Read ESPHome version...
FOR /F "tokens=* USEBACKQ" %%F IN (`esphome version`) DO (
  SET ESPHOME_LOCAL=%%F
)

rem read esphome remote version
echo Check for latest esphome version...
for /f "tokens=1,3" %%A in ('pip list --outdated --format=columns ^| findstr /I /R /C:"^esphome "') do set "ESPHOME_REMOTE=Version: %%B"

rem check if remote / no outdated version is emtpy, set local version
if "%ESPHOME_REMOTE%"=="" set "ESPHOME_REMOTE=%ESPHOME_LOCAL%"

rem if new version found, ask for update
if "%ESPHOME_REMOTE%" NEQ "%ESPHOME_LOCAL%" (
  :ask_update
  set opt=""
  set /P opt="New ESPHome version found! Do you like to update (y/n)?"
  rem set "opt=%opt:~0,1%"
  if /I "%opt%"=="y" goto:update
  if /I "%opt%"=="n" (
    echo Update skipped...  
    goto:startmenu
  )
  echo Please answer y or n.
  goto:ask_update
)

rem ################################################# 
rem #### startmenue                              ####
rem #################################################
:startmenu
rem cls
rem color 02
echo. 
echo ################################################# 
echo ####                                         #### 
echo ####          ESPHome Win Compile            #### 
echo ####          ===================            #### 
echo ####                                         #### 
echo ####    Created by: TheSmartGerman           #### 
echo ####                                         #### 
echo ################################################# 
echo ####                                         ####
echo ####  Current Settings:                      ####
echo ####  Installed ESPHome %ESPHOME_LOCAL%    ####
echo ####  Remote ESPHome %ESPHOME_REMOTE%       ####
echo ####                                         ####
echo ####  Remote IP Address: %hassip%     ####
echo ####                                         ####
echo ####                                         ####
echo ####                                         ####
echo ################################################# 
echo ####                                         #### 
echo ####   1 - Update given file(s)              ####
echo ####   2 - update all local files            ####
echo ####   3 - update files of list              ####
echo ####   4 - ESPHome update                    #### 
echo ####   5 - Set HA-Server ipadress            #### 
echo ####   6 - Copy To "sendto - entry"          ####
echo ####   7 - pio prune                         ####
echo ####   8 - free                              ####
echo ####   9 - Exit without erase                ####
echo ####   0 - Cleanup and Exit                  #### 
echo ####                                         #### 
echo #################################################
echo.

set /P opt="Your choice: "
set "opt=%opt:~0,1%"
color
if /i "%opt%"=="1" goto:compile
if /i "%opt%"=="2" goto:upall
if /i "%opt%"=="3" goto:upall_list
if /i "%opt%"=="4" goto:update
if /i "%opt%"=="5" goto:ipadress
if /i "%opt%"=="6" goto:sendto
if /i "%opt%"=="7" goto:cleanup_pio
if /i "%opt%"=="8" echo free && timeout 5 > NUL & goto:startmenu
if /i "%opt%"=="9" goto:exit
if /i "%opt%"=="0" goto:clearandexit
echo Wrong choice, trink less beer :-P
goto:startmenu

rem ################################################# 
rem #### esphome update                          ####
rem #################################################
:update
pip3 install esphome -U
goto:startup

rem ################################################# 
rem #### set ipaddress                           ####
rem #################################################
:ipadress
set /P hassip=Set new IP Address:
echo %hassip% > %TMP%\ip.tmp 
goto:startmenu

rem ################################################# 
rem #### sentto                                  ####
rem #################################################
:sendto
color
rem copy batch file to sendTo menue, if it's not already there
rem %APPDATA%\Microsoft\Windows\SendTo
rem %userprofile%\AppData\Roaming\Microsoft\Windows\SendTo
rem if not exist %userprofile%\AppData\Roaming\Microsoft\Windows\SendTo\%~n0%~x0 cp %~n0%~x0 %userprofile%\AppData\Roaming\Microsoft\Windows\SendTo\
rem echo %~n0%~x0
rem echo %~f0
copy /Y %~f0 %userprofile%\AppData\Roaming\Microsoft\Windows\SendTo\
goto:startmenu

rem ################################################# 
rem #### update all                              ####
rem #################################################
:upall
rem esphome -q update-all [directory containing yaml files]
esphome -q update-all .

rem ################################################# 
rem #### update list                             ####
rem #################################################
:upall_list
rem update all yaml files from a list
if not exist %TMP%\list.tmp (
	set hassip=192.168.178.100
) else (
	set /p hassip= < %TMP%\list.tmp
)

rem ################################################# 
rem #### compile                                 ####
rem #################################################
:compile
rem make sure no old data exists, may cause some trouble
if exist %TMP%\esphome\ rmdir /s /q %TMP%\esphome\

rem copy data from network share to local temp path
xcopy /e /k /h /i \\%hassip%\config\esphome\*.* %TMP%\esphome\

rem change work path + drive
cd /D %TMP%\esphome\
set count=0

rem Split the parameters on spaces but respect the quotes
echo Files given:
echo.
color 84
for %%G IN (!params!) do (
  set /a count+=1
  rem copy filename + extention into items
  set "item_!count!=%%~nG%%~xG"
  echo !count! %%~nG%%~xG
)
color 01
echo.

rem for /F "usebackq delims=" %%G in (`some-producer-of-quoted-names`) do (
rem   echo %%G
rem )

rem list the parameters
for /L %%n in (1,1,!count!) DO (
  rem echo %%n !item_%%n!
  rem compile for each file here
  esphome run --no-logs !item_%%n!
)
goto:startmenu

rem ################################################# 
rem #### cleanup_pio                             ####
rem #################################################
:cleanup_pio
rem pio system prune --dry-run
pio system prune
goto:startmenu

rem ################################################# 
rem ####  clear and exit                         ####
rem #################################################
:clearandexit
echo Cleaning up temporary files...
timeout 10 > NUL
rem del /f /s /q %TMP%\esphome\
rmdir /s /q %TMP%\esphome\
REM ** The exit is important, so the cmd.ex doesn't try to execute commands after ampersands
exit

rem ################################################# 
rem ####   exit                                  ####
rem #################################################
:exit
exit