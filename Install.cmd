:: Thanks Enderman, very cool.

@echo off
setlocal enabledelayedexpansion

:: Configuration
set "INSTALL_DIR=%ProgramFiles%\GifConverter"
set "MAX_ATTEMPTS=30"
set "VIDEO_FORMATS=mp4 mkv avi mov wmv flv webm m4v 3gp mpg mpeg vob ts mts m2ts divx xvid asf ogv rm rmvb m2v"
set "ANIMATION_FORMATS=webp apng mng swf flv f4v"

:: Main installation function
:main
    call :print_header
    call :check_admin_rights || exit /b 1
    call :install_dependencies || exit /b 1
    call :setup_converter || exit /b 1
    call :setup_context_menu || exit /b 1
    call :create_uninstaller || exit /b 1
    call :print_success
    exit /b 0

:print_header
    echo === GIF Converter Installation ===
    echo.
    exit /b 0

:check_admin_rights
    echo Checking administrator rights...
    net session >nul 2>&1
    if %errorLevel% neq 0 (
        echo ERROR: Please run as administrator
        pause
        exit /b 1
    )
    echo Admin rights confirmed
    exit /b 0

:check_program_available
    set "program=%~1"
    set "attempt=0"
    
    :check_loop
    where !program! >nul 2>&1
    if !errorLevel! equ 0 (
        echo !program! is now available
        exit /b 0
    )
    set /a "attempt+=1"
    if !attempt! geq %MAX_ATTEMPTS% (
        echo ERROR: Timed out waiting for !program! to become available
        exit /b 1
    )
    timeout /t 1 /nobreak >nul
    goto check_loop

:install_ffmpeg
    echo Installing FFmpeg...
    where ffmpeg >nul 2>&1
    if !errorLevel! equ 0 (
        echo FFmpeg: Already installed
        exit /b 0
    )

    winget install Gyan.FFmpeg -h --accept-source-agreements --accept-package-agreements
    if !errorLevel! neq 0 (
        echo ERROR: FFmpeg installation failed
        exit /b 1
    )
    
    call :check_program_available ffmpeg
    exit /b !errorLevel!

:install_chocolatey
    echo Installing Chocolatey...
    where choco >nul 2>&1
    if !errorLevel! equ 0 (
        echo Chocolatey: Already installed
        exit /b 0
    )

    if exist "C:\ProgramData\chocolatey\bin\choco.exe" (
        echo Found Chocolatey at standard location, adding to PATH...
        set "PATH=%PATH%;C:\ProgramData\chocolatey\bin"
        exit /b 0
    )

    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" 2>nul
    
    call :check_program_available choco
    if !errorLevel! equ 0 (
        set "PATH=%PATH%;C:\ProgramData\chocolatey\bin"
    )
    exit /b !errorLevel!

:install_gifsicle
    echo Installing Gifsicle...
    where gifsicle >nul 2>&1
    if !errorLevel! equ 0 (
        echo Gifsicle: Already installed
        exit /b 0
    )

    call :install_chocolatey || exit /b 1
    
    choco install gifsicle -y
    if !errorLevel! neq 0 (
        echo ERROR: Gifsicle installation failed
        exit /b 1
    )
    
    set "PATH=%PATH%;C:\ProgramData\chocolatey\bin"
    call :check_program_available gifsicle
    exit /b !errorLevel!

:install_dependencies
    echo Checking and installing dependencies...
    call :install_ffmpeg || exit /b 1
    call :install_gifsicle || exit /b 1
    echo All dependencies satisfied
    echo.
    exit /b 0

:setup_converter
    echo Setting up GIF Converter...
    mkdir "%INSTALL_DIR%" 2>nul
    call :create_converter_script
    exit /b !errorLevel!

:create_converter_script
    echo Creating converter script...
    (
        echo @echo off
        echo setlocal enabledelayedexpansion
        echo cd /d "%%~dp1"
        echo echo Converting "%%~nx1" to GIF...
        echo ffmpeg -i "%%~1" -vf "fps=15,scale=512:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "%%~n1.gif"
        echo if %%errorLevel%% neq 0 ^(
        echo     echo FFmpeg conversion failed
        echo     pause
        echo     exit /b 1
        echo ^)
        echo echo Optimizing GIF...
        echo gifsicle -O3 --lossy=80 "%%~n1.gif" -o "%%~n1.gif"
        echo if %%errorLevel%% neq 0 ^(
        echo     echo Gifsicle optimization failed
        echo     pause
        echo     exit /b 1
        echo ^)
        echo echo Conversion complete: "%%~n1.gif"
        echo pause
    ) > "%INSTALL_DIR%\ConvertToGif.cmd"
    exit /b 0

:setup_context_menu
    echo Adding context menu entries...
    for %%F in (%VIDEO_FORMATS%) do (
        call :add_context_menu_entry "%%F"
    )
    for %%F in (%ANIMATION_FORMATS%) do (
        call :add_context_menu_entry "%%F"
    )
    exit /b 0

:add_context_menu_entry
    set "ext=%~1"
    echo Adding support for .!ext! files...
    reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.!ext!\shell\ConvertToGif" /ve /d "Convert to GIF" /f
    reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.!ext!\shell\ConvertToGif\command" /ve /d "\"%INSTALL_DIR%\ConvertToGif.cmd\" \"%%1\"" /f
    exit /b 0

:create_uninstaller
    echo Creating uninstaller...
    call :generate_uninstaller_script
    exit /b !errorLevel!

:generate_uninstaller_script
    (
        echo @echo off
        echo setlocal enabledelayedexpansion
        echo net session ^>nul 2^>^&1
        echo if %%errorLevel%% neq 0 ^(
        echo     echo Run as administrator
        echo     pause
        echo     exit /b 1
        echo ^)
        echo echo Removing context menu entries...
        
        echo echo Removing video format entries...
        for %%F in (%VIDEO_FORMATS%) do (
            echo reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif" /f
        )
        
        echo echo Removing animation format entries...
        for %%F in (%ANIMATION_FORMATS%) do (
            echo reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif" /f
        )
        
        echo echo Removing program files...
        echo rmdir /s /q "%INSTALL_DIR%"
        echo echo.
        echo echo Uninstallation complete
        echo echo Note: FFmpeg and Gifsicle were not removed
        echo pause
    ) > "%INSTALL_DIR%\Uninstall.cmd"
    exit /b 0

:print_success
    echo.
    echo Installation completed successfully!
    echo You can now right-click on supported video files and select "Convert to GIF"
    echo To uninstall, run Uninstall.cmd from: %INSTALL_DIR%
    echo.
    pause
    exit /b 0

:: Start the installation
call :main
exit /b
