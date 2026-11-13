# წყაროს კონვერტაცია: .erf / .epf / .cf / .cfe ↔ XML

ამ ფაილს კითხულობ, როცა ამოცანა ეხება ბინარული 1C ფაილის XML-ად დაშლას (выгрузка в файлы / dump to files) ან XML-დან უკან აწყობას (загрузка из файлов / load from files) — ტიპურად Git-ში შენახვის, diff-ის, code review-ის, CI/CD-ის ან მასობრივი ტექსტური ჩასწორების მიზნით.

**მთავარი პრინციპი:** ერთადერთი სანდო გზა ნამდვილი, პლატფორმის ფორმატის XML-ის მისაღებად არის თავად 1C პლატფორმის გამოყენება (Designer პაკეტურ რეჟიმში, `ibcmd`, ან EDT-ის `ring`). მესამე მხარის ბინარული პარსერები (`v8unpack`, `tool1cd` და მისთანები) იძლევა კონტეინერის შიდა ფაილებს, და **არა** Designer-ის XML-ს — ისინი გამოდგება მხოლოდ სამძებრო/სადიაგნოსტიკო მიზნით, არა round-trip-ისთვის.

**ჯერ შეამოწმე: cc-1c-skills.** თუ პლაგინი [cc-1c-skills](https://github.com/Nikolay-Shirokov/cc-1c-skills) დაინსტალირებულია, კონვერტაცია აღარ სკრიპტია — ერთი სქილის გამოძახებაა. პარამეტრების აწყობაც, ლოგირებაც და exit-code-ის შემოწმებაც მას შიგნით აქვს:

| ამოცანა | Designer-ის გასაღები (ხელით) | cc-1c-skills სქილი |
|---|---|---|
| `.epf` / `.erf` → XML | `/DumpExternalDataProcessorOrReportToFiles` | `epf-dump` / `erf-dump` |
| XML → `.epf` / `.erf` | `/LoadExternalDataProcessorOrReportFromFiles` | `epf-build` / `erf-build` |
| კონფიგურაცია → XML | `/DumpConfigToFiles` | `db-dump-xml` |
| XML → კონფიგურაცია | `/LoadConfigFromFiles` | `db-load-xml` |
| გაფართოება (`.cfe`) ↔ XML | `… -Extension <სახელი>` | `db-dump-xml` / `db-load-xml -Extension <სახელი>` |
| ბინარული `.cf` | `/DumpCfg`, `/LoadCfg` | `db-dump-cf` / `db-load-cf` |
| `.dt` (მონაცემებით) | `/DumpIB`, `/RestoreIB` | `db-dump-dt` / `db-load-dt` |
| კონფიგურაციის განახლება ბაზაში | `/UpdateDBCfg` | `db-update` |

ბაზა არჩევა `.v8-project.json`-იდან; რეესტრი, ბაზის ამორჩევის ალგორითმი და ხაფანგები — [`cc-1c-skills-integration.md`](cc-1c-skills-integration.md)-ში. განსაკუთრებით დაიმახსოვრე: **`epf-dump`/`erf-dump` მოითხოვს ბაზას შესაბამისი კონფიგურაციით** — ცარიელ ბაზაში დაშლა ბმულოვან (ссылочные: `CatalogRef`, `DocumentRef`) ტიპებს ჩუმად ანადგურებს.

**როცა პლაგინი არ არის, მაგრამ shell და პლატფორმა გაქვს** (მაგ. Claude Code მომხმარებლის მანქანაზე — მოძებნე `C:\Program Files\1cv8\<ვერსია>\bin\1cv8.exe` ან `/opt/1cv8/x86_64/<ვერსია>/1cv8`), ბრძანება თვითონ გაუშვი, შედეგი გადაამოწმე და მომხმარებელს ანგარიში მიეცი. `1cv8.exe` PowerShell-იდან ან cmd-იდან გამოიძახე და არა Git Bash-იდან: Git Bash ნატიურ `.exe`-ს `/F`-ს `F:/`-ად გადასცემს, `/DisableStartupMessages`-ს კი `C:/Program Files/Git/DisableStartupMessages`-ად (თუ მაინც bash გჭირდება — `MSYS_NO_PATHCONV=1`). დაშლა ბაზას არ ცვლის; ჩატვირთვა კი (`/LoadConfigFromFiles`, `/LoadCfg`, `/UpdateDBCfg`) ცვლის — ის მხოლოდ იმ ბაზაზე გაუშვი, რომელიც მომხმარებელმა ამისთვის დაასახელა, და წინასწარ დაადასტურებინე.

**შენი როლი, როცა პლაგინი არ არის და shell-იც არ გაქვს.** თუ შენს გარემოში 1C არ დგას და მომხმარებლის მანქანაზე დისტანციური წვდომაც არ გაქვს, კონვერტაციას თვითონ ვერ გააკეთებ — ამიტომ:

1. დაადგინე ფაილის ტიპი, პლატფორმის ვერსია და ოპერაციული სისტემა (თუ არ იცი — ერთი მიზნობრივი შეკითხვა ქართულად).
2. აწყობ **მზა, გასაშვებ ბრძანებას ან სკრიპტს** (`.bat` / `.cmd` Windows-ისთვის, `.sh` Linux/macOS-ისთვის) სწორი გზებით.
3. ქართულად უხსნი რას აკეთებს თითოეული პარამეტრი, რა შეიძლება წავიდეს ცუდად და როგორ შეამოწმოს შედეგი.

---

## 1. ფაილის ტიპები და შესაბამისი ბრძანება

| გაფართოება | რა არის | Dump (→ XML) | Load (XML →) |
|---|---|---|---|
| `.erf` | გარე ანგარიში (внешний отчёт) | `/DumpExternalDataProcessorOrReportToFiles` | `/LoadExternalDataProcessorOrReportFromFiles` |
| `.epf` | გარე დამუშავება (внешняя обработка) | იგივე ბრძანება | იგივე ბრძანება |
| `.cf` | კონფიგურაციის მიწოდების ფაილი | `/DumpConfigToFiles` (ან `/DumpCfg` → `.cf`) | `/LoadConfigFromFiles` (ან `/LoadCfg`) |
| `.cfe` | გაფართოება (расширение конфигурации) | `/DumpConfigToFiles -Extension <name>` | `/LoadConfigFromFiles -Extension <name>` |
| `.dt` | ინფობაზის სრული ამონაწერი (მონაცემებით) | `/DumpIB` / `/RestoreIB` — **არა XML** | — |
| EDT project | EDT-ის საკუთარი ფაილური ფორმატი | `ring edt workspace export` | `ring edt workspace import` |

`.erf` და `.epf` ტექნიკურად ერთი და იგივე კონტეინერია — განსხვავება მხოლოდ ძირეული ობიექტის ტიპშია (Отчёт vs Обработка). ერთი და იგივე ბრძანება ორივეს ამუშავებს.

---

## 2. Designer პაკეტური რეჟიმი — გარე ანგარიშები და დამუშავებები

### 2.1 დაშლა XML-ად (.erf / .epf → XML)

```
/DumpExternalDataProcessorOrReportToFiles <корневой каталог выгрузки> <файл .epf|.erf> [-Format Plain|Hierarchical]
```

პრაქტიკული გამოძახება Windows-ზე (`C:\work\ib_copy` — სამუშაო ბაზის ასლი, იმ კონფიგურაციით, რომლისთვისაც ანგარიში დაიწერა):

```bat
"C:\Program Files\1cv8\8.3.27.1989\bin\1cv8.exe" DESIGNER ^
  /F "C:\work\ib_copy" ^
  /N "Администратор" /P "" ^
  /DisableStartupDialogs /DisableStartupMessages ^
  /DumpExternalDataProcessorOrReportToFiles "C:\work\src\SalesReport" "C:\work\SalesReport.erf" -Format Hierarchical ^
  /Out "C:\work\logs\dump.log" -NoTruncate
```

დაშლა კატალოგში ქმნის ძირეულ ფაილს `SalesReport.xml` და ქვეკატალოგს `SalesReport\`.

### 2.2 უკან აწყობა (XML → .erf / .epf)

```
/LoadExternalDataProcessorOrReportFromFiles <корневой файл выгрузки (.xml)> <файл .epf|.erf>
```

პირველი არგუმენტი **ძირეული XML-ფაილია**, არა კატალოგი. კატალოგის გადაცემისას Designer ბრძანებას ვერ ასრულებს, ფანჯარა ღია რჩება და პაკეტური სკრიპტი უსასრულოდ ელოდება.

```bat
"C:\Program Files\1cv8\8.3.27.1989\bin\1cv8.exe" DESIGNER ^
  /F "C:\work\ib_copy" ^
  /N "Администратор" /P "" ^
  /DisableStartupDialogs /DisableStartupMessages ^
  /LoadExternalDataProcessorOrReportFromFiles "C:\work\src\SalesReport\SalesReport.xml" "C:\work\SalesReport.erf" ^
  /Out "C:\work\logs\load.log" -NoTruncate
```

### 2.3 პარამეტრები, რომლებსაც ყოველთვის ურთავ

| პარამეტრი | რატომ |
|---|---|
| `/F <path>` ან `/S <server>\<base>` | Designer ყოველთვის მოითხოვს ინფობაზას. `.epf`/`.erf`-ისთვის ის **იმ კონფიგურაციას უნდა შეიცავდეს, რომლისთვისაც დამუშავება დაიწერა** — აიღე სამუშაო ბაზის ასლი. ცარიელ ბაზაში დაშლა exit-code 0-ით სრულდება, მაგრამ ბმულოვან ტიპებს სტრიქონად აქცევს (`cfg:CatalogRef.Валюты` → `xs:string`); ამ XML-იდან აწყობილი ფაილი დანაკარგს სამუდამოდ ინახავს, და იმავე ცარიელ ბაზაში round-trip ბაიტობრივად ემთხვევა — ანუ ვერაფერს ამჩნევს. ცარიელი ბაზა გამოდგება მხოლოდ `.cf`/`.cfe`-სთვის, სადაც კონფიგურაცია ჯერ მასში იტვირთება. |
| `/N` `/P` | მომხმარებელი/პაროლი. თუ ბაზაში ერთი მომხმარებელიცაა და უპაროლო — მაინც მიუთითე `/N`. თუ ბაზაში მომხმარებელი **საერთოდ არ არის** (მაგ. ახალი ბაზა), `/N`/`/P` არ გადასცე — მათთან Designer წყვეტს შეცდომით „Пользователь ИБ не идентифицирован". |
| `/DisableStartupDialogs` | თიშავს გაშვების დიალოგებს (მაგ. ავტორიზაციისას არასწორ პაროლზე) — მის გარეშე პაკეტური გაშვება შეიძლება „ჩამოეკიდოს" და ღილაკის დაჭერას დაელოდოს. |
| `/DisableStartupMessages` | თიშავს გაშვებისას გამოსულ შეტყობინებებს, რომლებიც პაკეტურ რეჟიმს „ჩამოკიდებს". |
| `/Out <file> -NoTruncate` | **კრიტიკულია** — შეცდომის ტექსტი მხოლოდ აქ ჩანს. `-NoTruncate` ინახავს წინა გაშვებების ლოგსაც. |
| `-Format Hierarchical` | იერარქიული ფორმატი — Git-ისთვის სწორი არჩევანი (ერთი ობიექტი = ერთი ფაილი, პატარა და გასაგები diff). `Plain` მხოლოდ ლეგასი თავსებადობისთვისაა. |

**გასაშვები კოდი (exit code):** `0` = წარმატება, ნებისმიერი სხვა = შეცდომა. `.bat`-ში შეამოწმე `if %ERRORLEVEL% neq 0`.

---

## 3. კონფიგურაციები და გაფართოებები (.cf / .cfe)

```bat
:: მთელი კონფიგურაცია → XML
1cv8.exe DESIGNER /F "C:\base" /N U /P P /DumpConfigToFiles "C:\src\cf" -format Hierarchical /Out log.txt

:: XML → კონფიგურაცია (ბაზაში) + ბაზის სტრუქტურის განახლება
1cv8.exe DESIGNER /F "C:\base" /N U /P P /LoadConfigFromFiles "C:\src\cf" /UpdateDBCfg /Out log.txt

:: კონკრეტული გაფართოება → XML
1cv8.exe DESIGNER /F "C:\base" /N U /P P /DumpConfigToFiles "C:\src\ext\MyExt" -Extension "MyExt" -format Hierarchical /Out log.txt

:: ყველა გაფართოება ერთბაშად
1cv8.exe DESIGNER /F "C:\base" /N U /P P /DumpConfigToFiles "C:\src\ext" -AllExtensions -format Hierarchical /Out log.txt

:: XML → გაფართოება
1cv8.exe DESIGNER /F "C:\base" /N U /P P /LoadConfigFromFiles "C:\src\ext\MyExt" -Extension "MyExt" /Out log.txt

:: ბინარული .cf / .cfe ფაილთან პირდაპირ
1cv8.exe DESIGNER /F "C:\base" /N U /P P /DumpCfg "C:\out\conf.cf" /Out log.txt
1cv8.exe DESIGNER /F "C:\base" /N U /P P /LoadCfg "C:\out\conf.cf" /UpdateDBCfg /Out log.txt
1cv8.exe DESIGNER /F "C:\base" /N U /P P /DumpCfg "C:\out\MyExt.cfe" -Extension "MyExt" /Out log.txt
```

**ინკრემენტული დაშლა.** დიდ კონფიგურაციაზე სრული `DumpConfigToFiles` ძალიან ნელია. გამოიყენე:

```
/DumpConfigToFiles "C:\src\cf" -update -force
```

`-update` ეხება მხოლოდ შეცვლილ ობიექტებს (ეყრდნობა კატალოგში არსებულ `ConfigDumpInfo.xml`-ს); `-force` აიძულებს სრულ დაშლას, თუ ვერსიები არ ემთხვევა. ანალოგიურად `/LoadConfigFromFiles ... -files <სია>` ან `-updateConfigDumpInfo` ჩატვირთვის დასაჩქარებლად.

**თანმიმდევრობა `.cf`-ის XML-ად გადასაყვანად, როცა ბაზა არ გაქვს:** შექმენი ცარიელი ფაილური ბაზა, ჩატვირთე `.cf` (`/LoadCfg`), მერე `/DumpConfigToFiles`. ბაზის შექმნა გაშვების ცალკე რეჟიმია და არა `DESIGNER`-ის გასაღები:

```bat
1cv8.exe CREATEINFOBASE File="C:\work\scratch_ib" /Out "C:\work\logs\create.log" /DisableStartupDialogs
```

ახალ ბაზაში მომხმარებლები არ არის, ამიტომ მომდევნო `DESIGNER /F "C:\work\scratch_ib"` გამოძახებებს `/N`/`/P` არ სჭირდება.

---

## 4. `ibcmd` — ავტონომიური სერვერის უტილიტა (8.3.20+)

`ibcmd` არ საჭიროებს Designer-ის GUI-ს და ზოგ ოპერაციას ინფობაზასთან მიერთების გარეშე ასრულებს — CI/CD-ისთვის უფრო სწრაფი და სტაბილურია.

```bash
# კონფიგურაცია → XML (კატალოგი პოზიციური არგუმენტია)
ibcmd infobase config export --db-path=/work/ib --user=Admin --password=pwd /work/src/cf

# XML → კონფიგურაცია
ibcmd infobase config import --db-path=/work/ib --user=Admin --password=pwd /work/src/cf
ibcmd infobase config apply --db-path=/work/ib --user=Admin --password=pwd --force

# ბინარული .cf (ფაილიც პოზიციური არგუმენტია)
ibcmd infobase config save --db-path=/work/ib /work/out/conf.cf
ibcmd infobase config load --db-path=/work/ib /work/out/conf.cf

# გაფართოება
ibcmd infobase config export --db-path=/work/ib --extension=MyExt /work/src/ext/MyExt

# გარე დამუშავება / ანგარიში → XML
ibcmd infobase config export --db-path=/work/ib --file=/work/SalesReport.erf /work/src/SalesReport
```

**გაფრთხილება:** `ibcmd`-ის ბრძანებები ვერსიიდან ვერსიაზე იცვლება — CI-ში ჩასმამდე გადაამოწმე `ibcmd help config` შენს ვერსიაზე. 8.3.27-ში:
- გზები პოზიციური არგუმენტებია: `--path=…` და `--file=…` (save/load-ისთვის) შეცდომას იძლევა „Ошибка разбора параметра";
- `config checksum` ბრძანება არ არსებობს;
- გარე დამუშავებას/ანგარიშს `export --file=` შლის, მაგრამ შედეგი Designer-ის დაშლას არ ემთხვევა — `.epf`/`.erf`-ის round-trip-ისთვის Designer დატოვე;
- Windows-ზე, სადაც სისტემური ლოკალი კირილიცული არ არის (ANSI code page ≠ 1251, მაგ. en-US), `ibcmd` არგუმენტებში კირილიცას `?`-ებად აქცევს: `export objects CommonModule.ДлительныеОперации` → „Объект метаданных CommonModule.?????? не существует". ასეთ მანქანაზე ობიექტების სიით ექსპორტი Designer-ით გააკეთე (`/DumpConfigToFiles … -listFile <ფაილი>`), რომელიც სიას ფაილიდან კითხულობს;
- ფაილურ ბაზაზე `ibcmd` ავტონომიური სერვერის მონაცემთა კატალოგს იყენებს (ნაგულისხმევად `%LOCALAPPDATA%\1C\1cv8\standalone-server`); CI-ში გადაეცი `--data=<დროებითი კატალოგი>`.

---

## 5. EDT (`ring`) — EDT პროექტი ↔ Designer XML

EDT-ს **საკუთარი** ფაილური ფორმატი აქვს; ის არ არის იგივე, რაც Designer-ის XML dump. კონვერტაცია `ring` უტილიტით ხდება:

```bash
# EDT პროექტი → Designer XML
ring edt workspace export \
  --workspace-location /work/ws \
  --project /work/projects/MyConf \
  --configuration-files /work/src/cf

# Designer XML → EDT პროექტი
ring edt workspace import \
  --workspace-location /work/ws \
  --configuration-files /work/src/cf \
  --project-name MyConf
```

შენიშვნები:
- `--workspace-location` მიუთითებს **დროებით** workspace-ზე; CI-ში ყოველ ჯერზე სუფთა კატალოგი აჯობებს.
- `ring edt` მოითხოვს დაინსტალირებულ EDT-ს შესაბამისი ვერსიით: `ring edt@2024.1 workspace export ...`.
- `ring` პირველი გაშვება ნელია (workspace-ის ინიციალიზაცია) — CI-ში გაითვალისწინე ტაიმაუტი.
- EDT-ის ვერსია და პლატფორმის ვერსია უნდა შეესაბამებოდეს პროექტს, თორემ იმპორტი ჩავარდება.

---

## 6. OneScript-ის ინსტრუმენტები (არჩევითი, მაგრამ მოსახერხებელი)

თუ მომხმარებელს OneScript უკვე აქვს, ეს ფენა მალავს ზემოთ აღწერილ „ხელით" ბრძანებებს:

```bash
opm install precommit1c vanessa-runner

# precommit1c — .epf/.erf ↔ XML (Designer-ს კულისებში იძახებს)
precommit1c --decompile ./epf ./src/epf
precommit1c --compile ./src/epf ./build --recursive
precommit1c --install                 # pre-commit hook მიმდინარე Git-რეპოზიტორიისთვის

# vanessa-runner 2.x (LTS)
vrunner decompileepf ./build/SalesReport.erf ./src/epf
vrunner compileepf ./src/epf ./build
vrunner decompile --in ./build/1Cv8.cf --out ./src/cf
vrunner compile --src ./src/cf --out ./build/1Cv8.cf
vrunner compileexttocfe --src ./src/cfe/MyExt --out ./build/MyExt.cfe

# vanessa-runner 3.0 — ბრძანებები ჯგუფებად დალაგდა
vrunner epf decompile ./build/SalesReport.erf --out ./src/epf
vrunner epf compile ./src/epf --out ./build
vrunner cf decompile ./src/cf --cf-file ./build/1Cv8.cf
vrunner cfe compile ./build/MyExt.cfe --src ./src/cfe/MyExt
```

`precommit1c`-ის ტიპური გამოყენება — Git-ის `pre-commit` hook (`precommit1c --install`), რომელიც commit-ის წინ ავტომატურად შლის ყველა შეცვლილ `.epf`/`.erf`-ს XML-ად, რათა რეპოზიტორიაში ტექსტი მოხვდეს და არა ბინარი. `vrunner`-ის 2.x და 3.0 ერთმანეთს არ ემთხვევა — სანამ ბრძანებას შესთავაზებ, გაარკვიე, რომელი ვერსია უყენია მომხმარებელს (`vrunner version`), და შეამოწმე `vrunner help`.

---

## 7. ტიპური ხაფანგები

- **ექსკლუზიური წვდომა.** Designer-ის ბევრი ბრძანება მოითხოვს, რომ ბაზაში სხვა სესია არ იყოს. ჩავარდნისას ლოგში ნახავ „база данных занята"-ს. CI-ში ჯერ `/S ... /IBConnectionString` მიერთებების შემოწმება ან ცალკე scratch ბაზა.
- **ვერსიების თავსებადობა.** ახალი პლატფორმით დაშლილი XML **ვერ** ჩაიტვირთება ძველ პლატფორმაში. სამუშაო ჯგუფში ყველამ ერთი და იგივე (ან თავსებადი) ვერსია უნდა გამოიყენოს. `/LoadExternalDataProcessorOrReportFromFiles`-ის შემთხვევაშიც იგივე წესი მოქმედებს.
- **`Plain` vs `Hierarchical` შერევა.** ერთხელ არჩეულ ფორმატს მიჰყევი. კატალოგში, სადაც უკვე დევს ერთი ფორმატის დაშლა, მეორის ჩაწერა არაპროგნოზირებად შედეგს იძლევა — ჯერ გაასუფთავე კატალოგი.
- **სამიზნე კატალოგი.** დაშლა კატალოგის შიგთავსს გადააწერს. ყოველთვის ცალკე კატალოგი თითო ობიექტზე, არა საერთო „dump" საქაღალდე.
- **კოდირება და ხაზის დაბოლოებები.** გამონატანი UTF-8-ია. Git-ში დაამატე `.gitattributes`, რომ Windows-ის `core.autocrlf`-მა XML არ დაამახინჯოს:
  ```
  *.xml   text eol=lf
  *.bsl   text eol=lf
  *.epf   binary
  *.erf   binary
  *.cf    binary
  *.cfe   binary
  ```
- **ბინარული ნაწილები.** სურათები, მაკეტების ბინარული მონაცემები და `Template`-ები ცალკე ფაილებად ინახება და XML-იდან მითითებით უკავშირდება — ისინი აუცილებლად უნდა მოხვდეს რეპოზიტორიაში, თორემ უკან აწყობა ჩავარდება.
- **გზები ჰარეებით.** ყოველთვის ბრჭყალებში. Windows-ის `.bat`-ში სტრიქონის გადატანა `^`-ით, არა `\`-ით.
- **Git Bash და `/`-იანი გასაღებები.** Git Bash (MSYS) ნატიური `.exe`-ის არგუმენტებს ფაილის გზებად „ასწორებს": `/F` → `F:/`, `/Out` → `C:/Program Files/Git/Out`. `1cv8.exe` გამოიძახე PowerShell-იდან ან cmd-იდან; bash-იდან მხოლოდ `MSYS_NO_PATHCONV=1`-ით.
- **`.bat`-ის ხაზის დაბოლოებები და კოდგვერდი.** `.bat` ფაილი უნდა შეინახო **CRLF**-ით — LF-ით `cmd.exe` არასწორად პარსავს (მაგ. `>nul` იშლება და „`ul` is not recognized" გამოდის). თუ ფაილში კირილიცა ან ქართულია (`/N "Администратор"`, ქართული `echo`), დაამატე `chcp 65001 >nul` `@echo off`-ის შემდეგ — თორემ ნაგულისხმევი კოდგვერდი (437/866) UTF-8 ბაიტებს დაამახინჯებს და 1C ავტორიზაციას ვერ გაივლის. `.sh`-ს კი პირიქით — მხოლოდ LF, თორემ `bad interpreter`.
- **პაროლები სკრიპტში.** არ ჩაშალო `/P` პაროლი ვერსიების კონტროლში მოხვედრილ ფაილში — გამოიყენე გარემოს ცვლადი ან CI secret.
- **`.dt` ≠ წყარო.** `.dt` არის ბაზის სრული ამონაწერი მონაცემებთან ერთად; ის Git-ისთვის არ გამოდგება. წყაროსთვის ყოველთვის XML.

---

## 8. მზა სკრიპტების შაბლონები

სკრიპტების სამუშაო ვერსიები დევს `scripts/` კატალოგში:

- `scripts/dump-erf.bat` — `.erf`/`.epf` → XML (Windows), შეცდომების შემოწმებით
- `scripts/load-erf.bat` — XML → `.erf`/`.epf` (Windows); იღებს ძირეულ `.xml`-ს ან დაშლის კატალოგს, რომელშიც ერთადერთ `.xml`-ს თვითონ პოულობს
- `scripts/dump-load.sh` — ორივე მიმართულება Linux/macOS-ისთვის

სამივე კითხულობს გარემოს ცვლადებს `IB`, `V8USER`, `V8PWD`, `V8` (ან შეცვალე ხაზები ფაილის თავში). `V8`-ის გარეშე იღებს უახლეს დაყენებულ 8.3 პლატფორმას და ბეჭდავს, რომელი აიღო; `V8USER`-ის გარეშე `/N`-ს არ გადასცემს (სწორია მომხმარებლების გარეშე ბაზისთვის); ლოგს წერს შედეგის გვერდით (`<კატალოგი>.dump.log`, `<ფაილი>.load.log`), რომ წყაროების კატალოგში არ მოხვდეს.

მომხმარებელს ყოველთვის აჩვენე სკრიპტი **მისი** რეალური გზებით შევსებული, და ცალკე ჩამოთვალე რა უნდა შეცვალოს (ბაზის გზა, მომხმარებელი, საჭიროების შემთხვევაში — პლატფორმა).

## 9. შედეგის გადამოწმება

1. **Exit code** = 0 და `/Out` ლოგში შეცდომა არ არის.
2. **დაშლის შემდეგ:** კატალოგში არსებობს ძირეული `.xml` ფაილი ობიექტის სახელით, `Ext/` ქვეკატალოგი მოდულებით (`ObjectModule.bsl`, `Form/Module.bsl`) და `Forms/`, `Templates/`.
3. **Round-trip ტესტი** — დაშალე → აწყვე → ისევ დაშალე მეორე კატალოგში → შეადარე (`diff -r`, `fc /L`). განსხვავება უნდა იყოს ნული (ან მხოლოდ დროის ნიშნულებში). თუ არა — ფორმატი ან ვერსია არ ემთხვევა. round-trip ამტკიცებს მხოლოდ იმას, რომ დაშლა და აწყობა ერთმანეთს ეთანხმება **იმავე ბაზაში**: თუ ბაზას კონფიგურაცია აკლდა, ორივე დაშლა ტიპს ერთნაირად კარგავს და diff ნულია. ამიტომ ძირეულ XML-ში ბმულოვანი ატრიბუტების ტიპებიც შეამოწმე — `xs:string` იქ, სადაც `cfg:CatalogRef.…` უნდა იყოს, დაკარგულ ტიპზე მიუთითებს.
4. **ფუნქციური შემოწმება:** გახსენი აწყობილი `.erf` Designer-ში ან 1C:Enterprise-ში და გაუშვი — სინტაქსური კონტროლი (`Синтаксический контроль`) სუფთა უნდა იყოს.
