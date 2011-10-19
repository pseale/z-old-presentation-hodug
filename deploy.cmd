@echo off

SET DIR=%~dp0%

if '%1'=='/?' goto usage
if '%1'=='-?' goto usage
if '%1'=='?' goto usage
if '%1'=='/help' goto usage
if '%1'=='help' goto usage

powershell -NoProfile -ExecutionPolicy unrestricted -Command "& '.\packages\psake.4.0.1.0\tools\psake.ps1' -tasklist deploy -param @{'environment'='dev'; 'versionNumber'='1.2.3.4'}"
pause

goto :eof
:usage
powershell -NoProfile -ExecutionPolicy unrestricted -Command "& '.\packages\psake.4.0.1.0\tools\psake-help.ps1'"