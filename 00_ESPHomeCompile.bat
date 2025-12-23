@echo off
title ESPHome Win Compile
rem https://community.home-assistant.io/t/compile-esphome-firmware-updates-on-a-windows-computer/675385

:startup
rem read ip settings
if not exist %TMP%\ip.tmp (
	set hassip=192.168.178.100
) else (
	set /p hassip= < %TMP%\ip.tmp
)

rem read esphome version
FOR /F "tokens=* USEBACKQ" %%F IN (`esphome version`) DO (
SET espversion=%%F
)

:startmenu
rem color 02
echo. 
echo ############################################## 
echo ####                                      #### 
echo ####         ESPHome Win Compile          #### 
echo ####         ===================          #### 
echo ####                                      #### 
echo ####   Created by: TheSmartGerman         #### 
echo ####                                      #### 
echo ############################################## 
echo ####                                      ####
echo ####  Current Settings:                   ####
echo ####  ESPHome %espversion%           ####
echo ####  Remote IP Address: %hassip%  ####
echo ####                                      ####
echo ####                                      ####
echo ####                                      ####
echo ############################################## 
echo ####                                      #### 
echo ####   1 - Update given file(s)           ####
echo ####   2 - update all local fils          ####
echo ####   3 - ESPHome update                 #### 
echo ####   4 - ipadress                       #### 
echo ####   5 - sendto - entry                 ####
echo ####   6 - pio prune                      ####
echo ####   9 - Exit without erase             ####
echo ####   0 - Cleanup and Exit               #### 
echo ####                                      #### 
echo ##############################################
echo.

set /P opt=Your choice:
color
if /i "%opt%"=="1" goto:compile
if /i "%opt%"=="2" goto:upall
if /i "%opt%"=="3" goto:update
if /i "%opt%"=="4" goto:ipadress
if /i "%opt%"=="5" goto:sendto
if /i "%opt%"=="6" goto:cleanup
if /i "%opt%"=="9" goto:exit
if /i "%opt%"=="0" goto:clearandexit
echo Wrong choice, trink less beer :-P
goto:startmenu

:update
pip3 install esphome -U
goto:startup

:ipadress
set /P hassip=Set new IP Address:
echo %hassip% > %TMP%\ip.tmp 
goto:startup


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

:upall
rem esphome -q update-all [directory containing yaml files]
esphome -q update-all .

:compile
rem make sure no old data exists, may cause some trouble
if exist %TMP%\esphome\ rmdir /s /q %TMP%\esphome\

rem copy data from network share to local temp path
xcopy /e /k /h /i \\%hassip%\config\esphome\*.* %TMP%\esphome\

rem change work path + drive
cd /D %TMP%\esphome\


rem https://stackoverflow.com/questions/1243240/drag-and-drop-batch-file-for-multiple-files
setlocal ENABLEDELAYEDEXPANSION
rem Take the cmd-line, remove all until the first parameter
set "params=!cmdcmdline:~0,-1!"
set "params=!params:*" =!"
set count=0

rem Split the parameters on spaces but respect the quotes
echo Files given:
color 1
for %%G IN (!params!) do (
  set /a count+=1
  rem copy filename + extention into items
  set "item_!count!=%%~nG%%~xG"
  echo !count! %%~nG%%~xG
)

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

:cleanup
rem pio system prune --dry-run
pio system prune
goto:startmenu

:clearandexit
timeout 10 > NUL
rem del /f /s /q %TMP%\esphome\
rmdir /s /q %TMP%\esphome\
REM ** The exit is important, so the cmd.ex doesn't try to execute commands after ampersands
exit

:exit
exit