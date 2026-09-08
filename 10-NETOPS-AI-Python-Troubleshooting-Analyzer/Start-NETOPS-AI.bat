@echo off
cd /d "%~dp0"
py -3.13 src\netops_ai.py
if errorlevel 1 pause
