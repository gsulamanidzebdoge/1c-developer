@echo off
rem ფაილი UTF-8-შია — კირილიცა/ქართული რომ სწორად წაიკითხოს კონსოლმა
rem (ნაგულისხმევი კოდგვერდი 437/866 მათ დაამახინჯებდა და /N-ს გატეხდა).
chcp 65001 >nul
rem ============================================================
rem  .erf / .epf  ->  XML  (выгрузка в файлы)
rem  შეცვალე ქვემოთ 4 ცვლადი შენს გარემოზე
rem ============================================================
setlocal

set "V8=C:\Program Files\1cv8\8.3.24.1548\bin\1cv8.exe"
set "IB=C:\work\scratch_ib"
set "USER=Администратор"
set "PWD="

set "SRCFILE=%~1"
set "OUTDIR=%~2"

if "%SRCFILE%"=="" (
  echo Usage: dump-erf.bat ^<file.erf^|file.epf^> ^<output-xml-dir^>
  exit /b 2
)
if "%OUTDIR%"=="" (
  echo Usage: dump-erf.bat ^<file.erf^|file.epf^> ^<output-xml-dir^>
  exit /b 2
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "LOG=%OUTDIR%\_dump.log"

"%V8%" DESIGNER /F "%IB%" /N "%USER%" /P "%PWD%" ^
  /DisableStartupMessages ^
  /DumpExternalDataProcessorOrReportToFiles "%OUTDIR%" "%SRCFILE%" -Format Hierarchical ^
  /Out "%LOG%" -NoTruncate

if %ERRORLEVEL% neq 0 (
  echo [FAIL] exit code %ERRORLEVEL% - იხილე ლოგი: %LOG%
  type "%LOG%"
  exit /b %ERRORLEVEL%
)

echo [OK] დაშლილია: %OUTDIR%
endlocal
