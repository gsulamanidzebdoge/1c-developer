# წყაროს კონვერტაცია: .erf / .epf / .cf / .cfe ↔ XML

ამ ფაილს კითხულობ, როცა ამოცანა ეხება ბინარული 1C ფაილის XML-ად დაშლას (выгрузка в файлы / dump to files) ან XML-დან უკან აწყობას (загрузка из файлов / load from files) — ტიპურად Git-ში შენახვის, diff-ის, code review-ის, CI/CD-ის ან მასობრივი ტექსტური ჩასწორების მიზნით.

**მთავარი პრინციპი:** ერთადერთი სანდო გზა ნამდვილი, პლატფორმის ფორმატის XML-ის მისაღებად არის თავად 1C პლატფორმის გამოყენება (Designer პაკეტურ რეჟიმში, `ibcmd`, ან EDT-ის `ring`). მესამე მხარის ბინარული პარსერები (`v8unpack`, `tool1cd` და მისთანები) იძლევა კონტეინერის შიდა ფაილებს, და **არა** Designer-ის XML-ს — ისინი გამოდგება მხოლოდ სამძებრო/სადიაგნოსტიკო მიზნით, არა round-trip-ისთვის.

**შენი როლი:** შენ ჩვეულებრივ ვერ ასრულებ კონვერტაციას თვითონ (1C პლატფორმა შენს გარემოში არ დგას). ამიტომ:
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

პრაქტიკული გამოძახება Windows-ზე:

```bat
"C:\Program Files\1cv8\8.3.24.1548\bin\1cv8.exe" DESIGNER ^
  /F "C:\work\scratch_ib" ^
  /N "Администратор" /P "" ^
  /DisableStartupMessages ^
  /DumpExternalDataProcessorOrReportToFiles "C:\work\src\SalesReport" "C:\work\SalesReport.erf" -Format Hierarchical ^
  /Out "C:\work\logs\dump.log" -NoTruncate
```

### 2.2 უკან აწყობა (XML → .erf / .epf)

```bat
"C:\Program Files\1cv8\8.3.24.1548\bin\1cv8.exe" DESIGNER ^
  /F "C:\work\scratch_ib" ^
  /N "Администратор" /P "" ^
  /DisableStartupMessages ^
  /LoadExternalDataProcessorOrReportFromFiles "C:\work\src\SalesReport" "C:\work\SalesReport.erf" ^
  /Out "C:\work\logs\load.log" -NoTruncate
```

### 2.3 პარამეტრები, რომლებსაც ყოველთვის ურთავ

| პარამეტრი | რატომ |
|---|---|
| `/F <path>` ან `/S <server>\<base>` | Designer ყოველთვის მოითხოვს ინფობაზას, თუნდაც გარე ფაილთან სამუშაოდ. გამოიყენე ცალკე **სამუშაო (scratch) ცარიელი ფაილური ბაზა** — არ დაბლოკო სამუშაო ბაზა. |
| `/N` `/P` | მომხმარებელი/პაროლი. თუ ბაზაში ერთი მომხმარებელიცაა და უპაროლო — მაინც მიუთითე `/N`. |
| `/DisableStartupMessages` | თიშავს დიალოგებს, რომლებიც პაკეტურ რეჟიმს „ჩამოკიდებს". |
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

**თანმიმდევრობა `.cf`-ის XML-ად გადასაყვანად, როცა ბაზა არ გაქვს:** შექმენი ცარიელი ფაილური ბაზა (`/CreateInfoBase "File=C:\work\scratch_ib;"`), ჩატვირთე `.cf` (`/LoadCfg`), მერე `/DumpConfigToFiles`.

---

## 4. `ibcmd` — ავტონომიური სერვერის უტილიტა (8.3.20+)

`ibcmd` არ საჭიროებს Designer-ის GUI-ს და ზოგ ოპერაციას ინფობაზასთან მიერთების გარეშე ასრულებს — CI/CD-ისთვის უფრო სწრაფი და სტაბილურია.

```bash
# კონფიგურაცია → XML
ibcmd infobase config export --db-path=/work/ib --user=Admin --password=pwd --path=/work/src/cf

# XML → კონფიგურაცია
ibcmd infobase config import --db-path=/work/ib --user=Admin --password=pwd --path=/work/src/cf
ibcmd infobase config apply --db-path=/work/ib --user=Admin --password=pwd --force

# ბინარული .cf
ibcmd infobase config save --db-path=/work/ib --file=/work/out/conf.cf
ibcmd infobase config load --db-path=/work/ib --file=/work/out/conf.cf

# გაფართოება
ibcmd infobase config export --db-path=/work/ib --extension=MyExt --path=/work/src/ext/MyExt

# შემოწმება: ემთხვევა თუ არა ბაზის კონფიგურაცია შენახულს
ibcmd infobase config checksum --db-path=/work/ib
```

**გაფრთხილება:** `ibcmd`-ის ბრძანებების შემადგენლობა ვერსიიდან ვერსიაზე შესამჩნევად იზრდება (მაგ. ექსპორტი/იმპორტი ბაზასთან მიერთების გარეშე და `config checksum` შედარებით გვიან დაემატა). `.erf`/`.epf` **გარე** ფაილებზე `ibcmd` ტრადიციულად არ მუშაობს — გარე ანგარიშებისთვის დარჩი Designer-ზე. ყოველთვის გადაამოწმე `ibcmd help infobase config` შენს კონკრეტულ ვერსიაზე, სანამ სკრიპტს CI-ში ჩასვამ.

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
opm install precommit1c v8runner vanessa-runner

# .epf/.erf დაშლა Git-ისთვის (Designer-ს იძახებს კულისებში)
precommit1c decompile ./epf
precommit1c compile ./epf

# CI-ისთვის
vrunner compileexttoepf ./src/SalesReport ./build/SalesReport.erf
vrunner decompile --src ./src --out ./build
```

`precommit1c`-ის ტიპური გამოყენება — Git-ის `pre-commit` hook, რომელიც commit-ის წინ ავტომატურად შლის ყველა შეცვლილ `.epf`/`.erf`-ს XML-ად, რათა რეპოზიტორიაში ტექსტი მოხვდეს და არა ბინარი.

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
- **`.bat`-ის ხაზის დაბოლოებები და კოდგვერდი.** `.bat` ფაილი უნდა შეინახო **CRLF**-ით — LF-ით `cmd.exe` არასწორად პარსავს (მაგ. `>nul` იშლება და „`ul` is not recognized" გამოდის). თუ ფაილში კირილიცა ან ქართულია (`/N "Администратор"`, ქართული `echo`), დაამატე `chcp 65001 >nul` `@echo off`-ის შემდეგ — თორემ ნაგულისხმევი კოდგვერდი (437/866) UTF-8 ბაიტებს დაამახინჯებს და 1C ავტორიზაციას ვერ გაივლის. `.sh`-ს კი პირიქით — მხოლოდ LF, თორემ `bad interpreter`.
- **პაროლები სკრიპტში.** არ ჩაშალო `/P` პაროლი ვერსიების კონტროლში მოხვედრილ ფაილში — გამოიყენე გარემოს ცვლადი ან CI secret.
- **`.dt` ≠ წყარო.** `.dt` არის ბაზის სრული ამონაწერი მონაცემებთან ერთად; ის Git-ისთვის არ გამოდგება. წყაროსთვის ყოველთვის XML.

---

## 8. მზა სკრიპტების შაბლონები

სკრიპტების სამუშაო ვერსიები დევს `scripts/` კატალოგში:

- `scripts/dump-erf.bat` — `.erf`/`.epf` → XML (Windows), შეცდომების შემოწმებით
- `scripts/load-erf.bat` — XML → `.erf`/`.epf` (Windows)
- `scripts/dump-load.sh` — ორივე მიმართულება Linux/macOS-ისთვის

მომხმარებელს ყოველთვის აჩვენე სკრიპტი **მისი** რეალური გზებით შევსებული, და ცალკე ჩამოთვალე რა უნდა შეცვალოს (პლატფორმის ვერსია, ბაზის გზა, მომხმარებელი).

## 9. შედეგის გადამოწმება

1. **Exit code** = 0 და `/Out` ლოგში შეცდომა არ არის.
2. **დაშლის შემდეგ:** კატალოგში არსებობს ძირეული `.xml` ფაილი ობიექტის სახელით, `Ext/` ქვეკატალოგი მოდულებით (`ObjectModule.bsl`, `Form/Module.bsl`) და `Forms/`, `Templates/`.
3. **Round-trip ტესტი** — ეს არის მთავარი შემოწმება: დაშალე → აწყვე → ისევ დაშალე მეორე კატალოგში → შეადარე (`diff -r`, `fc /L`). განსხვავება უნდა იყოს ნული (ან მხოლოდ დროის ნიშნულებში). თუ არა — ფორმატი ან ვერსია არ ემთხვევა.
4. **ფუნქციური შემოწმება:** გახსენი აწყობილი `.erf` Designer-ში ან 1C:Enterprise-ში და გაუშვი — სინტაქსური კონტროლი (`Синтаксический контроль`) სუფთა უნდა იყოს.
