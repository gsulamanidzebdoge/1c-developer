@echo off
rem ფაილი UTF-8-შია — კირილიცა/ქართული რომ სწორად წაიკითხოს კონსოლმა
rem (ნაგულისხმევი კოდგვერდი 437/866 მათ დაამახინჯებდა და /N-ს გატეხდა).
chcp 65001 >nul
rem ============================================================
rem  .erf / .epf  ->  XML  (выгрузка в файлы)
rem  გამოყენება: dump-erf.bat <file.erf|file.epf> <output-xml-dir>
rem
rem  IB — ბაზა იმ კონფიგურაციით, რომლისთვისაც დამუშავება დაიწერა
rem  (მაგ. სამუშაო ბაზის ასლი). ცარიელ ბაზაში დაშლისას ბმულოვანი
rem  ტიპები (CatalogRef.* და სხვ.) შეცდომის გარეშე იკარგება.
rem  ცვლადები აქ შეცვალე ან გარემოს ცვლადებით გადაეცი.
rem ============================================================
setlocal

if not defined IB set "IB=C:\work\ib_copy"
rem V8USER / V8PWD — მხოლოდ იმ ბაზისთვის, რომელშიც მომხმარებლები არსებობს.
rem მომხმარებლების გარეშე ბაზაში ზედმეტი /N შეცდომას იძლევა
rem „Пользователь ИБ не идентифицирован", ამიტომ ასეთ დროს ცარიელი დატოვე.
rem set "V8USER=Администратор"
rem set "V8PWD="
set "AUTH="
if defined V8USER set AUTH=/N "%V8USER%" /P "%V8PWD%"
rem V8 — 1cv8.exe-ის სრული გზა; თუ არ არის მითითებული, აიღება უახლესი დაყენებული 8.3
if not defined V8 call :find_v8
if not exist "%V8%" (
  echo [FAIL] 1cv8.exe ვერ მოიძებნა: "%V8%" - მიუთითე V8 ცვლადი
  exit /b 3
)

set "SRCFILE=%~1"
set "OUTDIR=%~2"
if "%SRCFILE%"=="" goto usage
if "%OUTDIR%"=="" goto usage

if not exist "%OUTDIR%" mkdir "%OUTDIR%"
rem ლოგი გამოტანის კატალოგის გვერდით, რომ Git-ში არ მოხვდეს
set "LOG=%OUTDIR%.dump.log"
echo platform: %V8%

"%V8%" DESIGNER /F "%IB%" %AUTH% ^
  /DisableStartupDialogs /DisableStartupMessages ^
  /DumpExternalDataProcessorOrReportToFiles "%OUTDIR%" "%SRCFILE%" -Format Hierarchical ^
  /Out "%LOG%" -NoTruncate

if %ERRORLEVEL% neq 0 (
  echo [FAIL] exit code %ERRORLEVEL% - იხილე ლოგი: %LOG%
  type "%LOG%"
  exit /b %ERRORLEVEL%
)
echo [OK] დაშლილია: %OUTDIR%
endlocal
exit /b 0

:usage
echo Usage: dump-erf.bat ^<file.erf^|file.epf^> ^<output-xml-dir^>
exit /b 2

:find_v8
rem 8.3.??.* — ორნიშნა ქვევერსიები; სახელით დალაგებისას ბოლო ყველაზე ახალია
for /f "delims=" %%v in ('dir /b /ad /on "%ProgramFiles%\1cv8\8.3.??.*" 2^>nul') do (
  if exist "%ProgramFiles%\1cv8\%%v\bin\1cv8.exe" set "V8=%ProgramFiles%\1cv8\%%v\bin\1cv8.exe"
)
exit /b 0
