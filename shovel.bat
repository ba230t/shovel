@echo off
setlocal enabledelayedexpansion
pushd %~dp0

:MENU
    set commands=help install uninstall
    set help[help]=Show this message.
    set help[install]=Install an app. curl and 7z are required.
    set help[uninstall]=Uninstall an app.
    
    set ini=%~dp0\config.ini
    set target=%1
    for %%a in (%commands%) do (
        if "%target%"=="%%a" (
            call :%target% %2 %3 %4 %5 %6 %7 %8 %9
            exit /b
        )
    )
    goto :HELP
    exit /b

:HELP
    echo Usage: %~n0 ^<command^> [args]
    echo.
    echo Commands:
    for %%a in (%commands%) do (
        set pad=            ;
        set buf=%%a!pad!
        echo   !buf:~0,12! !help[%%a]!
    )
    exit /b

:INSTALL
    if "%1"=="" (echo Usage: %~n0 install ^<app^> && exit /b)
    set app=%1
    call :GET_INI %app% "url" url %ini%
    if "%url%"=="" (echo %app% is not defined. && exit /b)
    if exist "apps\%app%" (echo %app% is already installed. && exit /b)

    mkdir apps cache shims persist > NUL 2>&1
    if not exist "cache\%app%.zip" (curl %url% -o "cache\%app%.zip")
    7z x -o"apps\%app%" "cache\%app%.zip" -y

    for /l %%i in (0,1,9) do (
        if "%%i"=="0" (set suffix=) else (set suffix=%%i)
        call :GET_INI %app% "bin!suffix!" bin %ini%
        call :GET_INI %app% "persist!suffix!" persist %ini%
        call :BASENAME "!bin!" shim
        
        if "!shim!" neq "" (
            mklink "shims\!shim!" "..\apps\%app%\!bin!"
        )
        if "!persist!" neq "" (
            mkdir persist\%app%\!persist! & mklink /d "apps\%app%\!persist!" "..\..\persist\%app%\!persist!"
        )
    )
    exit /b

:UNINSTALL
    if "%1"=="" (echo Usage: %~n0 uninstall ^<app^> && exit /b)
    set app=%1
    call :GET_INI %app% "url" url %ini%
    if "%url%"=="" (echo %app% is not defined. && exit /b)
    if not exist "apps\%app%" (echo %app% is not installed. && exit /b)

    for /l %%i in (0,1,9) do (
        if "%%i"=="0" (set suffix=) else (set suffix=%%i)
        call :GET_INI %app% "bin!suffix!" bin %ini%
        call :BASENAME "!bin!" shim
        
        if "!shim!" neq "" (
            call :EXECUTE del shims\!shim!
        )
    )
    call :EXECUTE rmdir /s/q apps\%app%
    exit /b

:EXECUTE
    echo %*
    cmd /c %*
    exit /b

:BASENAME
	set %2=%~nx1
	exit /b

:GET_INI
    :: GET_INI 1:section 2:key 3:variable 4:inifile
    set GI_ret=
    set GI_sec=
    for /f "usebackq eol=; delims== tokens=1,2" %%a in (%4) do (
       set GI_key=%%a
       set GI_bra?=!GI_key:~0,1!!GI_key:~-1,1!
       set GI_sec?=!GI_key:~1,-1!
       if "!GI_bra?!"=="[]" set GI_sec=!GI_sec?!
       if "!GI_sec!"=="%~1" if "!GI_key!"=="%~2" (
          set GI_ret=%%b
          goto GI_EXIT
       )
    )
    set GI_ret=
    :GI_EXIT
        set %3=%GI_ret%
        exit /b

