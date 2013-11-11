@echo off
REM ###########################################################################################################
REM #                                                                                                         #
REM # File:          getAllReports.bat                                                                        #
REM #                                                                                                         #
REM # Purpose:       Wrapper script for executing a PowerShell with PowerCLI extension & the main routine     #
REM #                                                                                                         #
REM # Author:        Sven Sperner <cethss@gmail.com>                                                          #
REM #                                                                                                         #
REM # Last edited:   08.05.2012                                                                               #
REM #                                                                                                         #
REM # Requirements:  Microsoft Windows Command line or Task scheduler                                         #
REM #                                                                                                         #
REM # Usage:                                                                                                  #
REM #   cmd:         <drive>:\<path>\getAllReports.bat                                                        #
REM #   task:        System Tools -> Scheduled Tasks -> Add Scheduled Task                                    #
REM #                -> Next -> Browse... -> [select "getAllReports.bat"], Open                               #
REM #                -> [name the task], [select for example "Monthly"] -> Next                               #
REM #                -> [set start time], Next -> [set username & password] -> Next                           #
REM #                -> Finish                                                                                #
REM #                                                                                                         #
REM #                    This program is distributed in the hope that it will be useful,                      #
REM #                    but WITHOUT ANY WARRANTY; without even the implied warranty of                       #
REM #                    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                                 #
REM #                                                                                                         #
REM ###########################################################################################################

echo %0 is running



REM Read configuration file:
REM ------------------------
FOR /f %%c IN ('dir /b *.ini') DO (
	FOR /f "tokens=1,2 delims==" %%a IN (%%c) DO (
		IF %%a==psConsoleFile SET psConsoleFile=%%b
		IF %%a==installPath SET installPath=%%b
		IF %%a==logsDir SET logsDir=%%b
		IF %%a==mainRoutineFile SET mainRoutineFile=%%b
	)
)



REM Get date and create log:
REM ------------------------
SET "datef=%date:~-4%-%date:~3,2%-%date:~0,2%"
SET "logfile=%installPath%\%logsDir%\%datef%.log"
echo See %logfile% for status
echo %0 started at %date% %time% >> "%logfile%" 2>&1



REM Run the main routine:
REM ---------------------
echo . >> "%logfile%" 2>&1
echo ################################################### >> "%logfile%" 2>&1
echo # Starting main routine at %date% %time% # >> "%logfile%" 2>&1
echo ################################################### >> "%logfile%" 2>&1
echo . >> "%logfile%" 2>&1
REM Logging prevents from sending log file, so step one for fetching, step two for sending
PowerShell -PSConsoleFile "%psConsoleFile%" -command "%installPath%\%mainRoutineFile% -dontSend" >> "%logfile%" 2>&1
PowerShell -PSConsoleFile "%psConsoleFile%" -command "%installPath%\%mainRoutineFile% -onlySend"
echo . >> "%logfile%" 2>&1
echo ################################################### >> "%logfile%" 2>&1
echo # Main routine finished at %date% %time% # >> "%logfile%" 2>&1
echo ################################################### >> "%logfile%" 2>&1
echo . >> "%logfile%" 2>&1



rem pause
REM DONE!
