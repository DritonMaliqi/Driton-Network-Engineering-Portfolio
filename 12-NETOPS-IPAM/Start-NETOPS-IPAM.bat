@echo off
cd /d "%~dp0"
py -3.13 netops_ipam.py
if errorlevel 1 pause

