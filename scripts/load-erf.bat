@echo off
rem ფაილი UTF-8-შია — კირილიცა/ქართული რომ სწორად წაიკითხოს კონსოლმა
rem (ნაგულისხმევი კოდგვერდი 437/866 მათ დაამახინჯებდა და /N-ს გატეხდა).
chcp 65001 >nul
rem ============================================================
rem  XML  ->  .erf / .epf  (загрузка из файлов)
rem ============================================================
setlocal

set "V8=C:\Program Files\1cv8\8.3.24.1548\bin\1cv8.exe"
set "IB=C:\work\scratch_ib"
set "USER=Администратор"
set "PWD="

set "SRCDIR=%~1"
set "OUTFILE=%~2"

if "%SRCDIR%"=="" (
  echo Usage: load-erf.bat ^<xml-dir^> ^<out.erf^|out.epf^>
  exit /b 2
)
if "%OUTFILE%"=="" (
  echo Usage: load-erf.bat ^<xml-dir^> ^<out.erf^|out.epf^>
  exit /b 2
)

set "LOG=%SRCDIR%\_load.log"

"%V8%" DESIGNER /F "%IB%" /N "%USER%" /P "%PWD%" ^
  /DisableStartupMessages ^
  /LoadExternalDataProcessorOrReportFromFiles "%SRCDIR%" "%OUTFILE%" ^
  /Out "%LOG%" -NoTruncate

if %ERRORLEVEL% neq 0 (
  echo [FAIL] exit code %ERRORLEVEL% - იხილე ლოგი: %LOG%
  type "%LOG%"
  exit /b %ERRORLEVEL%
)

echo [OK] აწყობილია: %OUTFILE%
endlocal
