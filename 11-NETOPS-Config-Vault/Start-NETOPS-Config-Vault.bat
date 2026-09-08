@echo off
cd /d "%~dp0"
py -3.13 netops_backup.py
if errorlevel 1 pause

