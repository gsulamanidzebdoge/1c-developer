# Georgian Terminology & Output Templates (ქართული ტერმინოლოგია)

Use this to keep Georgian output natural and consistent. Georgian-speaking 1C developers routinely mix in the canonical Russian/English terms, so the right style is **clear Georgian prose with the established technical term kept alongside** (often in parentheses) — not a forced, unfamiliar calque. When in doubt, name the concept in Georgian and put the canonical term in parentheses the first time.

## Reusable Georgian section headings

Use these headings to structure your three-step output:

- `## არქიტექტურული გეგმა` — architectural plan (analysis step)
- `## მეტამონაცემების სტრუქტურა` — metadata structure
- `## კოდი` — code
- `## ლოგიკის ახსნა` — explanation of the logic
- `## ტესტირება` — testing
- `## სასაზღვრო შემთხვევები` — edge cases
- `## შენიშვნები / რისკები` — notes / risks
- `## ინტეგრაციის სქემა` — integration / exchange scheme
- `## შეფასების შეჯამება` — review summary (review mode)
- `## კრიტიკული საკითხები` — critical issues (review mode)
- `## რა არის კარგად` — what's done well (review mode)

## Terminology table

| Concept | Georgian (ქართული) | Russian (canonical) | English |
|---|---|---|---|
| Configuration | კონფიგურაცია | Конфигурация | Configuration |
| Metadata object | მეტამონაცემების ობიექტი | Объект метаданных | Metadata object |
| Catalog | ცნობარი | Справочник | Catalog |
| Document | დოკუმენტი | Документ | Document |
| Information register | ცნობების რეგისტრი | Регистр сведений | Information register |
| Accumulation register | დაგროვების რეგისტრი | Регистр накопления | Accumulation register |
| Accounting register | ბუღალტრული რეგისტრი | Регистр бухгалтерии | Accounting register |
| Calculation register | გაანგარიშების რეგისტრი | Регистр расчёта | Calculation register |
| Enumeration | ჩამონათვალი | Перечисление | Enumeration |
| Constant | კონსტანტა | Константа | Constant |
| Chart of accounts | ანგარიშთა გეგმა | План счетов | Chart of accounts |
| Characteristic kinds | მახასიათებლების სახეები | План видов характеристик | Characteristic kinds |
| Dimension | განზომილება | Измерение | Dimension |
| Resource | რესურსი | Ресурс | Resource |
| Attribute | რეკვიზიტი | Реквизит | Attribute |
| Predefined item | წინასწარ განსაზღვრული ელემენტი | Предопределённый элемент | Predefined item |
| Posting (a document) | გატარება | Проведение | Posting |
| Document posted | დოკუმენტი გატარდა | Документ проведён | Document posted |
| Balance | ნაშთი | Остаток | Balance |
| Turnover | ბრუნვა | Оборот | Turnover |
| Movement / register record | მოძრაობა (ჩანაწერი) | Движение | Movement / record |
| Query | მოთხოვნა | Запрос | Query |
| Query language | მოთხოვნების ენა | Язык запросов | Query language |
| Virtual table | ვირტუალური ცხრილი | Виртуальная таблица | Virtual table |
| Temp table | დროებითი ცხრილი | Временная таблица | Temp table |
| Slice of last | ბოლო ჭრილი | Срез последних | Slice of last |
| Managed form | მართვადი ფორმა | Управляемая форма | Managed form |
| Server | სერვერი | Сервер | Server |
| Client | კლიენტი | Клиент | Client |
| Compilation directive | კომპილაციის დირექტივა | Директива компиляции | Compilation directive |
| Common module | საერთო მოდული | Общий модуль | Common module |
| Object module | ობიექტის მოდული | Модуль объекта | Object module |
| Manager module | მენეჯერის მოდული | Модуль менеджера | Manager module |
| Form module | ფორმის მოდული | Модуль формы | Form module |
| Data lock | მონაცემთა ბლოკირება | Блокировка данных | Data lock |
| Managed locks | მართვადი ბლოკირებები | Управляемые блокировки | Managed locks |
| Deadlock | ურთიერთბლოკირება | Взаимоблокировка | Deadlock |
| Transaction | ტრანზაქცია | Транзакция | Transaction |
| Exception handling | გამონაკლისების დამუშავება | Обработка исключений | Exception handling |
| Try / Except | ცდა / გამონაკლისი | Попытка / Исключение | Try / Except |
| Index | ინდექსი | Индекс | Index |
| Row-level security (RLS) | ჩანაწერის დონის უსაფრთხოება | Ограничение доступа на уровне записей (RLS) | Row-level security |
| Standard Subsystems Library | სტანდარტული ქვესისტემების ბიბლიოთეკა (БСП) | Библиотека стандартных подсистем (БСП) | Standard Subsystems Library (SSL) |
| Development standards | დეველოპმენტის სტანდარტები | Стандарты разработки | Development standards |
| Event log | რეგისტრაციის ჟურნალი | Журнал регистрации | Event log |
| Edge case | სასაზღვრო შემთხვევა | Граничный случай | Edge case |
| Configuration extension | კონფიგურაციის გაფართოება | Расширение конфигурации | Configuration extension |
| Borrowed object | ნასესხები ობიექტი | Заимствованный объект | Borrowed object |
| Annotation (extension) | ანოტაცია | Аннотация | Annotation |
| Asynchronous | ასინქრონული | Асинхронный | Asynchronous |
| Async / Await | ასინქრონული / ლოდინი (Асинх/Ждать) | Асинх / Ждать | Async / Await |
| Promise | დაპირება (Обещание) | Обещание | Promise |
| HTTP service | HTTP-სერვისი | HTTP-сервис | HTTP service |
| Web service | ვებ-სერვისი | Веб-сервис | Web service |
| Data exchange | მონაცემთა გაცვლა | Обмен данными | Data exchange |
| Exchange plan | გაცვლის გეგმა | План обмена | Exchange plan |
| Universal exchange format | უნივერსალური გაცვლის ფორმატი | EnterpriseData (универсальный формат) | EnterpriseData |
| Data conversion | მონაცემთა კონვერტაცია | Конвертация данных | Data conversion |
| Background job | ფონური დავალება | Фоновое задание | Background job |
| Scheduled job | რეგლამენტური დავალება | Регламентное задание | Scheduled job |
| Long operation | ხანგრძლივი ოპერაცია | Длительная операция | Long operation |
| Functional option | ფუნქციური ოფცია | Функциональная опция | Functional option |
| Event subscription | მოვლენების გამოწერა | Подписка на события | Event subscription |
| Dynamic list | დინამიკური სია | Динамический список | Dynamic list |
| Access right | წვდომის უფლება | Право доступа | Access right |
| Role | როლი | Роль | Role |
| Configurator (Designer) | კონფიგურატორი | Конфигуратор | Designer |
| 1C:EDT | 1C:EDT (Eclipse-ის გარემო) | 1С:EDT | 1C:EDT |
| Code review | კოდის რევიუ | Ревью кода | Code review |

## Style reminders

- Write full, natural Georgian sentences in explanations — not telegraphic fragments and not literal word-for-word translations of Russian.
- Keep code keywords, method names, and metadata identifiers in their 1C form (Russian-syntax by default); only the surrounding prose and comments are Georgian.
- The first time a heavy technical term appears, give the Georgian plus the canonical term once, then you can use the shorter form.
- For user-facing UI strings inside the code, always provide a Georgian variant inside `НСтр(...)`, e.g. `НСтр("ru = 'Готово'; ka = 'მზადაა'")`.
