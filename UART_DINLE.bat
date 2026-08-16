@echo off
REM ==========================================================================
REM  Nazik Ormanlar - UART Dinleyici
REM  Cift tiklayarak baslatir (varsayilan COM8).
REM  Baska port icin asagidaki COM8'i degistirin.
REM ==========================================================================
title Nazik Ormanlar - Basys3 Refleks Oyunu / UART Dinleyici
mode con: cols=100 lines=45
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uart_dinle.ps1" -Port COM8
pause
