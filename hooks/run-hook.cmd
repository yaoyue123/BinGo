@echo off
REM Polyglot hook wrapper for BinGo
REM This file exists for Windows compatibility
REM On Unix-like systems, session-start.sh is executed directly

setlocal

set "SCRIPT_DIR=%~dp0"
set "PLUGIN_ROOT=%SCRIPT_DIR%.."

REM On Windows with Git Bash or WSL, delegate to bash
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%PLUGIN_ROOT%\hooks\session-start.sh" %*
    exit /b %ERRORLEVEL%
)

if exist "C:\WSL\Ubuntu\ubuntu.exe" (
    C:\WSL\Ubuntu\ubuntu.exe bash "%PLUGIN_ROOT%\hooks\session-start.sh" %*
    exit /b %ERRORLEVEL%
)

REM If no bash available, output minimal context
echo {
echo   "hookSpecificOutput": {
echo     "hookEventName": "SessionStart",
echo     "additionalContext": "BinGo binary vulnerability mining skills available. See SKILL.md for details."
echo   }
echo }

endlocal
