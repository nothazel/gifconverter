:: Thanks Enderman, very cool.

@echo off
setlocal enabledelayedexpansion

echo === GIF Converter Installation ===
echo Checking dependencies...

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as administrator
    pause
    exit /b 1
)

:: Check FFmpeg
where ffmpeg >nul 2>&1
if %errorLevel% neq 0 (
    echo FFmpeg not found, installing...
    winget install Gyan.FFmpeg -h --accept-source-agreements --accept-package-agreements
    if %errorLevel% neq 0 (
        echo ERROR: FFmpeg installation failed
        pause
        exit /b 1
    )
    
    :: Verify FFmpeg is in PATH after installation
    where ffmpeg >nul 2>&1
    if %errorLevel% neq 0 (
        echo ERROR: FFmpeg installed but not found in PATH
        echo Please restart your computer and run the installer again
        pause
        exit /b 1
    )
) else (
    echo FFmpeg: Already installed
)

:: Check Gifsicle
where gifsicle >nul 2>&1
if %errorLevel% neq 0 (
    echo Gifsicle not found, installing...
    
    :: Check for scoop
    where scoop >nul 2>&1
    if %errorLevel% neq 0 (
        echo Installing Scoop package manager...
        powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
        powershell -Command "iwr -useb get.scoop.sh | iex"
        if %errorLevel% neq 0 (
            echo ERROR: Scoop installation failed
            pause
            exit /b 1
        )
    )
    
    scoop install gifsicle
    if %errorLevel% neq 0 (
        echo ERROR: Gifsicle installation failed
        pause
        exit /b 1
    )
    
    :: Verify Gifsicle is in PATH after installation
    where gifsicle >nul 2>&1
    if %errorLevel% neq 0 (
        echo ERROR: Gifsicle installed but not found in PATH
        echo Please restart your computer and run the installer again
        pause
        exit /b 1
    )
) else (
    echo Gifsicle: Already installed
)

echo All dependencies satisfied
echo.
echo Setting up GIF Converter...

:: Create directory and files
set "INSTALL_DIR=%ProgramFiles%\GifConverter"
mkdir "%INSTALL_DIR%" 2>nul

:: Create converter script
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

:: Add registry entries for all supported formats
echo Adding context menu entries...

:: Video Formats
for %%F in (
    mp4 mkv avi mov wmv flv 
    webm m4v 3gp mpg mpeg 
    vob ts mts m2ts divx xvid 
    asf ogv rm rmvb m2v
) do (
    echo Adding support for .%%F files...
    reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif" /ve /d "Convert to GIF" /f
    reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif\command" /ve /d "\"%INSTALL_DIR%\ConvertToGif.cmd\" \"%%1\"" /f
)

:: Animation Formats
for %%F in (
    webp apng mng swf flv f4v
) do (
    echo Adding support for .%%F files...
    reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif" /ve /d "Convert to GIF" /f
    reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif\command" /ve /d "\"%INSTALL_DIR%\ConvertToGif.cmd\" \"%%1\"" /f
)

:: Create uninstaller
echo Creating uninstaller...
echo @echo off > "%INSTALL_DIR%\Uninstall.cmd"
echo setlocal enabledelayedexpansion >> "%INSTALL_DIR%\Uninstall.cmd"
echo net session ^>nul 2^>^&1 >> "%INSTALL_DIR%\Uninstall.cmd"
echo if %%errorLevel%% neq 0 ^( >> "%INSTALL_DIR%\Uninstall.cmd"
echo     echo Run as administrator >> "%INSTALL_DIR%\Uninstall.cmd"
echo     pause >> "%INSTALL_DIR%\Uninstall.cmd"
echo     exit /b 1 >> "%INSTALL_DIR%\Uninstall.cmd"
echo ^) >> "%INSTALL_DIR%\Uninstall.cmd"
echo echo Removing context menu entries... >> "%INSTALL_DIR%\Uninstall.cmd"
echo echo Removing video format entries... >> "%INSTALL_DIR%\Uninstall.cmd"

:: Add video format removals
(for %%F in (
    mp4 mkv avi mov wmv flv 
    webm m4v 3gp mpg mpeg 
    vob ts mts m2ts divx xvid 
    asf ogv rm rmvb m2v
) do (
    echo reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif" /f
)) >> "%INSTALL_DIR%\Uninstall.cmd"

echo echo Removing animation format entries... >> "%INSTALL_DIR%\Uninstall.cmd"

:: Add animation format removals
(for %%F in (
    webp apng mng swf flv f4v
) do (
    echo reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.%%F\shell\ConvertToGif" /f
)) >> "%INSTALL_DIR%\Uninstall.cmd"

echo echo Removing program files... >> "%INSTALL_DIR%\Uninstall.cmd"
echo rmdir /s /q "%INSTALL_DIR%" >> "%INSTALL_DIR%\Uninstall.cmd"
echo echo. >> "%INSTALL_DIR%\Uninstall.cmd"
echo echo Uninstallation complete >> "%INSTALL_DIR%\Uninstall.cmd"
echo echo Note: FFmpeg and Gifsicle were not removed >> "%INSTALL_DIR%\Uninstall.cmd"
echo pause >> "%INSTALL_DIR%\Uninstall.cmd"