@echo off
REM Document Portal GCP Management Scripts
REM Choose setup or cleanup

echo.
echo ========================================
echo   Document Portal GCP Management
echo ========================================
echo.
echo 1. Setup GCP Infrastructure
echo 2. Cleanup GCP Infrastructure  
echo 3. Exit
echo.

set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto setup
if "%choice%"=="2" goto cleanup
if "%choice%"=="3" goto exit
echo Invalid choice. Please try again.
pause
goto :eof

:setup
echo.
echo Starting GCP Setup...
echo.
set /p groq_key="Enter your GROQ API key: "
set /p google_key="Enter your Google AI API key: "
set /p langchain_key="Enter your LangChain API key (optional, press Enter to skip): "

if "%langchain_key%"=="" (
    powershell -ExecutionPolicy Bypass -File "scripts\setup-gcp.ps1" -GroqApiKey "%groq_key%" -GoogleApiKey "%google_key%"
) else (
    powershell -ExecutionPolicy Bypass -File "scripts\setup-gcp.ps1" -GroqApiKey "%groq_key%" -GoogleApiKey "%google_key%" -LangchainApiKey "%langchain_key%"
)
pause
goto :eof

:cleanup
echo.
echo ==========================================
echo WARNING: This will DELETE ALL GCP resources!
echo ==========================================
echo.
set /p confirm="Are you sure? Type YES to continue: "
if not "%confirm%"=="YES" (
    echo Cleanup cancelled.
    pause
    goto :eof
)

echo.
echo Starting GCP Cleanup...
echo.
set /p force_choice="Skip confirmation prompts? (y/n): "
if /i "%force_choice%"=="y" (
    powershell -ExecutionPolicy Bypass -File "scripts\cleanup-gcp.ps1" -Force
) else (
    powershell -ExecutionPolicy Bypass -File "scripts\cleanup-gcp.ps1"
)
pause
goto :eof

:exit
echo Goodbye!
