@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 0.1.5
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=node "%appdata%\npm\node_modules\kuduSync\bin\kuduSync"
)
IF NOT DEFINED DEPLOYMENT_TEMP (
  SET DEPLOYMENT_TEMP=%temp%\___deployTemp%random%
  SET CLEAN_LOCAL_DEPLOYMENT_TEMP=true
)

IF DEFINED CLEAN_LOCAL_DEPLOYMENT_TEMP (
  echo Creating deployment temp at %DEPLOYMENT_TEMP%
  IF EXIST "%DEPLOYMENT_TEMP%" rd /s /q "%DEPLOYMENT_TEMP%"
  mkdir "%DEPLOYMENT_TEMP%"
)

IF NOT DEFINED MSBUILD_PATH (
  SET MSBUILD_PATH=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\msbuild.exe
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling .NET Web Application deployment.

:: 1. Restore NuGet packages
echo 1: Skipping Restore NuGet packages - for some reason this section doesn't work in Azure
::IF NOT DEFINED NUGET_EXE (
::  echo Missing nuget.exe path, checking for local executable
::  IF EXIST "%DEPLOYMENT_SOURCE%\.nuget\NuGet.exe" (
::     echo Missing nuget.exe path, using local executable from package restore
::	 SET NUGET_EXE="%DEPLOYMENT_SOURCE%\.nuget\NuGet.exe"
::  ) ELSE (
::    echo Missing nuget.exe path and package restore not set, cannot continue
::    goto error
::  )
::)

::IF /I "CloudPixiesAndGhosts.sln" NEQ "" (
::  echo - Nuget Package Restore using Nuget.exe located at: %NUGET_EXE%
::  call "%NUGET_EXE%" restore "%DEPLOYMENT_SOURCE%\CloudPixiesAndGhosts.sln"
::  IF !ERRORLEVEL! NEQ 0 goto error
::)

:: 2. Tests
echo 2: Build and execute tests

echo 2a: Executing Unit Tests: CloudSiteTests
%MSBUILD_PATH% "%DEPLOYMENT_SOURCE%\CloudSiteTests\CloudSiteTests.csproj" /nologo /verbosity:m /t:Build /p:Configuration=Debug
call "tools/nunit-console.exe" "%DEPLOYMENT_SOURCE%\CloudSiteTests\bin\Debug\CloudSiteTests.dll"

echo 2b: Executing Interface Tests: CloudPixiesTests
%MSBUILD_PATH% "%DEPLOYMENT_SOURCE%\CloudPixiesTests\CloudPixiesTests.csproj" /nologo /verbosity:m /t:Build /p:Configuration=UITest
call "tools/nunit-console-x86.exe" "%DEPLOYMENT_SOURCE%\CloudPixiesTests\bin\UITest\CloudPixiesTests.dll"

IF !ERRORLEVEL! NEQ 0 goto error

:: 3. Build to the temporary path
echo 3: Build to the temporary path
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  echo - Build
  %MSBUILD_PATH% "%DEPLOYMENT_SOURCE%\CloudSite\CloudSite.csproj" /nologo /verbosity:m /t:Build /t:pipelinePreDeployCopyAllFilesToOneFolder /p:_PackageTempDir="%DEPLOYMENT_TEMP%";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release /p:SolutionDir="%DEPLOYMENT_SOURCE%\.\\" %SCM_BUILD_ARGS%
) ELSE (
  %MSBUILD_PATH% "%DEPLOYMENT_SOURCE%\CloudSite\CloudSite.csproj" /nologo /verbosity:m /t:Build /p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release /p:SolutionDir="%DEPLOYMENT_SOURCE%\.\\" %SCM_BUILD_ARGS%
)

IF !ERRORLEVEL! NEQ 0 goto error

:: 4. KuduSync
echo 4: KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  echo - KuduSync 
  call %KUDU_SYNC_CMD% -v 50 -f "%DEPLOYMENT_TEMP%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Post deployment stub
echo Post deployment stub starting
call %POST_DEPLOYMENT_ACTION%
IF !ERRORLEVEL! NEQ 0 goto error

goto end

:error
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
echo Finished successfully.
