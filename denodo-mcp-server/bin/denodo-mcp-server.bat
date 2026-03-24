@echo off
REM ---------------------------------------------------------------------------
REM  Environment variable JAVA_HOME must be set and exported
REM ---------------------------------------------------------------------------

IF "%OS%" == "Windows_NT" setlocal ENABLEDELAYEDEXPANSION

SET BIN_DIR=%~dp0
SET DIST_DIR=%BIN_DIR%\..
SET LOG_FILE=%DIST_DIR%\config\log4j2.xml
SET LIB_DIR=%DIST_DIR%\lib

REM ---------------------------------
REM COMPUTE JAVA EXECUTABLE COMMAND
REM ---------------------------------

SET JAVA_BIN="%JAVA_HOME%\bin\java.exe"
IF EXIST "%JAVA_HOME%" GOTO opts
SET JAVA_BIN="java"

:opts
IF NOT EXIST "%JAVA_OPTS%" (
    SET JAVA_OPTS="-Xmx1024m"
)


REM ---------------------------------
REM OUTPUT EXECUTION ENVIRONMENT
REM ---------------------------------

IF EXIST "%JAVA_BIN%" (
	%JAVA_BIN% %JAVA_OPTS% -Dlogging.config="%LOG_FILE%" -Dloader.path="%LIB_DIR%" -jar "%LIB_DIR%"\denodo-mcp-server-9-20260317.jar --spring.config.location=file:../config/
	goto end
)
echo "Unable to execute '%0': No java executable found and/or no JAVA_HOME variable set"
:end