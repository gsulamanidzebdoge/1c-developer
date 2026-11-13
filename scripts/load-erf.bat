@echo off
rem ფაილი UTF-8-შია — კირილიცა/ქართული რომ სწორად წაიკითხოს კონსოლმა
rem (ნაგულისხმევი კოდგვერდი 437/866 მათ დაამახინჯებდა და /N-ს გატეხდა).
chcp 65001 >nul
rem ============================================================
rem  XML  ->  .erf / .epf  (загрузка из файлов)
rem  გამოყენება: load-erf.bat <root.xml|dump-dir> <out.erf|out.epf>
rem
rem  პლატფორმა ელის ძირეულ XML-ფაილს (<Имя>.xml) და არა კატალოგს;
rem  კატალოგის გადაცემისას სკრიპტი მასში ერთადერთ .xml-ს პოულობს.
rem  IB — ბაზა იმ კონფიგურაციით, რომლისთვისაც დამუშავება დაიწერა.
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

set "SRC=%~1"
set "OUTFILE=%~2"
if "%SRC%"=="" goto usage
if "%OUTFILE%"=="" goto usage

set "ROOTXML=%SRC%"
if exist "%SRC%\" (
  call :find_root_xml "%SRC%"
  if errorlevel 1 exit /b 2
)
if not exist "%ROOTXML%" (
  echo [FAIL] ძირეული XML ვერ მოიძებნა: "%ROOTXML%"
  exit /b 2
)

rem ლოგი შედეგის ფაილის გვერდით, რომ წყაროების კატალოგი სუფთა დარჩეს
set "LOG=%OUTFILE%.load.log"
echo platform: %V8%
echo source:   %ROOTXML%

"%V8%" DESIGNER /F "%IB%" %AUTH% ^
  /DisableStartupDialogs /DisableStartupMessages ^
  /LoadExternalDataProcessorOrReportFromFiles "%ROOTXML%" "%OUTFILE%" ^
  /Out "%LOG%" -NoTruncate

if %ERRORLEVEL% neq 0 (
  echo [FAIL] exit code %ERRORLEVEL% - იხილე ლოგი: %LOG%
  type "%LOG%"
  exit /b %ERRORLEVEL%
)
echo [OK] აწყობილია: %OUTFILE%
endlocal
exit /b 0

:usage
echo Usage: load-erf.bat ^<root.xml^|dump-dir^> ^<out.erf^|out.epf^>
exit /b 2

:find_root_xml
set "ROOTXML="
set "XMLCOUNT=0"
for %%f in ("%~1\*.xml") do (
  set "ROOTXML=%%~ff"
  set /a XMLCOUNT+=1
)
if not "%XMLCOUNT%"=="1" (
  echo [FAIL] "%~1"-ში მოსალოდნელია ზუსტად ერთი .xml, ნაპოვნია %XMLCOUNT% - გადაეცი ძირეული .xml პირდაპირ
  exit /b 2
)
exit /b 0

:find_v8
rem 8.3.??.* — ორნიშნა ქვევერსიები; სახელით დალაგებისას ბოლო ყველაზე ახალია
for /f "delims=" %%v in ('dir /b /ad /on "%ProgramFiles%\1cv8\8.3.??.*" 2^>nul') do (
  if exist "%ProgramFiles%\1cv8\%%v\bin\1cv8.exe" set "V8=%ProgramFiles%\1cv8\%%v\bin\1cv8.exe"
)
exit /b 0
