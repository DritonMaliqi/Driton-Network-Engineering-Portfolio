@echo off
cd /d "%~dp0"
py -3.13 netops_syslog.py
if errorlevel 1 pause
