# Worked Example: End-to-End Managed Form + Posting

A single, coherent example that shows the skill's principles working **together**: metadata choice, client/server separation, a server-without-context call, document posting with a managed lock and balance control, set-based queries via virtual tables, the async client model and `НСтр` localization. Use it as a template for how the pieces fit — adapt, don't copy blindly.

## Scenario

"When a goods-issue document (`РеализацияТоваров`) is posted, it must not drive warehouse stock negative. The user also wants a *Check availability* button on the form that reports shortages before they try to post."

## Metadata (analysis step output, normally written in Georgian)

- **Документ «РеализацияТоваров»** — the business event; lines in a tabular section «Товары» (Номенклатура, Количество); real-time posting (оперативное проведение) allowed.
- **Регистр накопления «ТоварыНаСкладах»** (balance kind) — dimensions Склад, Номенклатура; resource Количество. Stock lives here; posting writes Расход movements.
- Current stock is read from the `.Остатки` virtual table — never recomputed from documents.
- Concurrency: two users posting issues for the same goods must not both pass the balance check on the same units → the posting transaction takes a **managed exclusive lock** on the touched register dimensions before it writes and reads.

## 1. Common module «УчетТоваровСервер» (server)

Flags: **Сервер** only. Both callers — posting and the form's `&НаСервереБезКонтекста` function — already run on the server, so the module needs no «Вызов сервера».

The two callers ask different questions, so there are two functions:
- the form asks *before* posting whether the current balance covers the document → `ДефицитПоТоварам`;
- posting asks *after* writing its own movements — when the balance already includes this document's issue — whether any balance went negative → `ОтрицательныеОстатки`. Comparing "required > balance" at that point subtracts the document's quantity twice and refuses a valid posting (10 in stock, issue 6: the balance read after the write is 4, and 6 > 4).

```bsl
#Область ПрограммныйИнтерфейс

// აბრუნებს პოზიციებს, რომლებზეც საწყობის მიმდინარე ნაშთი მოთხოვნილ რაოდენობას არ ჰყოფნის.
// ერთი მოთხოვნით, ციკლის გარეშე; ერთი ნომენკლატურის რამდენიმე სტრიქონი წინასწარ ჯამდება.
// გატარებამდე იძახება - მაგალითად, ფორმის ბრძანებიდან „ხელმისაწვდომობის შემოწმება".
//
// Параметры:
//  Склад  - СправочникСсылка.Склады
//  Товары - ТаблицаЗначений - სვეტები Номенклатура, Количество
//
// Возвращаемое значение:
//  ТаблицаЗначений - სვეტები Номенклатура, Требуется, Остаток
//
Функция ДефицитПоТоварам(Склад, Товары) Экспорт

    Требуется = Товары.Скопировать(, "Номенклатура, Количество");
    Требуется.Свернуть("Номенклатура", "Количество");

    Запрос = Новый Запрос;
    Запрос.Текст =
        "ВЫБРАТЬ
        |    Т.Номенклатура КАК Номенклатура,
        |    Т.Количество КАК Количество
        |ПОМЕСТИТЬ ВтТребуется
        |ИЗ
        |    &Требуется КАК Т
        |
        |ИНДЕКСИРОВАТЬ ПО
        |    Номенклатура
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |ВЫБРАТЬ
        |    Остатки.Номенклатура КАК Номенклатура,
        |    Остатки.КоличествоОстаток КАК КоличествоОстаток
        |ПОМЕСТИТЬ ВтОстатки
        |ИЗ
        |    РегистрНакопления.ТоварыНаСкладах.Остатки(
        |            ,
        |            Склад = &Склад
        |                И Номенклатура В
        |                    (ВЫБРАТЬ
        |                        ВтТребуется.Номенклатура КАК Номенклатура
        |                    ИЗ
        |                        ВтТребуется КАК ВтТребуется)) КАК Остатки
        |
        |ИНДЕКСИРОВАТЬ ПО
        |    Номенклатура
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |ВЫБРАТЬ
        |    Т.Номенклатура КАК Номенклатура,
        |    Т.Количество КАК Требуется,
        |    ЕСТЬNULL(Остатки.КоличествоОстаток, 0) КАК Остаток
        |ИЗ
        |    ВтТребуется КАК Т
        |        ЛЕВОЕ СОЕДИНЕНИЕ ВтОстатки КАК Остатки
        |        ПО Т.Номенклатура = Остатки.Номенклатура
        |ГДЕ
        |    Т.Количество > ЕСТЬNULL(Остатки.КоличествоОстаток, 0)";

    Запрос.УстановитьПараметр("Требуется", Требуется);
    Запрос.УстановитьПараметр("Склад", Склад);

    Возврат Запрос.Выполнить().Выгрузить();

КонецФункции

// აბრუნებს პოზიციებს, რომლებზეც საწყობის ნაშთი უარყოფითია.
// გატარებისას იძახება, მოძრაობების ჩაწერის შემდეგ: ნაშთი უკვე შეიცავს ამ დოკუმენტის ხარჯს,
// ამიტომ „საჭირო > ნაშთი" რაოდენობას ორჯერ გამოაკლებდა - ვამოწმებთ მხოლოდ უარყოფითობას.
//
// Параметры:
//  Склад        - СправочникСсылка.Склады
//  Номенклатура - Массив из СправочникСсылка.Номенклатура
//
// Возвращаемое значение:
//  ТаблицаЗначений - სვეტები Номенклатура, Остаток (უარყოფითი)
//
Функция ОтрицательныеОстатки(Склад, Номенклатура) Экспорт

    Запрос = Новый Запрос;
    Запрос.Текст =
        "ВЫБРАТЬ
        |    Остатки.Номенклатура КАК Номенклатура,
        |    Остатки.КоличествоОстаток КАК Остаток
        |ИЗ
        |    РегистрНакопления.ТоварыНаСкладах.Остатки(
        |            ,
        |            Склад = &Склад
        |                И Номенклатура В (&Номенклатура)) КАК Остатки
        |ГДЕ
        |    Остатки.КоличествоОстаток < 0";

    Запрос.УстановитьПараметр("Склад", Склад);
    Запрос.УстановитьПараметр("Номенклатура", Номенклатура);

    Возврат Запрос.Выполнить().Выгрузить();

КонецФункции

#КонецОбласти
```

Notes: one query batch per question (no query in a loop); lines of the same item are summed first (`Свернуть`), so 3 + 3 against a balance of 5 is a shortage; the filters sit **inside** the virtual-table parameters; the virtual table goes into its own temp table before the join, because the 1C standards advise against joining a virtual table directly; both temp tables are indexed on the join field; only the needed columns are selected, each with an alias. `ТаблицаЗначений` goes back only to server code.

## 2. Object module of «РеализацияТоваров» — posting with lock + balance control

```bsl
#Область ОбработчикиСобытий

Процедура ОбработкаПроведения(Отказ, РежимПроведения)

    // 1) მოძრაობები ცხრილური ნაწილიდან - ნაკრებად, სტრიქონზე მოთხოვნის გარეშე
    Движения.ТоварыНаСкладах.Записывать = Истина;
    Для Каждого СтрокаТовара Из Товары Цикл
        Движение = Движения.ТоварыНаСкладах.Добавить();
        Движение.ВидДвижения  = ВидДвиженияНакопления.Расход;
        Движение.Период       = Дата;
        Движение.Склад        = Склад;
        Движение.Номенклатура = СтрокаТовара.Номенклатура;
        Движение.Количество   = СтрокаТовара.Количество;
    КонецЦикла;

    // 2) ნაშთის კონტროლი მხოლოდ ოპერატიული გატარებისას
    Если РежимПроведения <> РежимПроведенияДокумента.Оперативный Тогда
        Возврат;
    КонецЕсли;

    ТоварыДокумента = Товары.Выгрузить(, "Номенклатура");
    ТоварыДокумента.Свернуть("Номенклатура");

    // ბლოკირება ნაშთის წაკითხვამდე. სივრცე თვით რეგისტრია: "...ТоварыНаСкладах.Остатки"
    // შესრულებისას შეცდომას იძლევა „Неверное имя пространства блокировок"
    Блокировка = Новый БлокировкаДанных;
    ЭлементБлокировки = Блокировка.Добавить("РегистрНакопления.ТоварыНаСкладах");
    ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
    ЭлементБлокировки.УстановитьЗначение("Склад", Склад);
    ЭлементБлокировки.ИсточникДанных = ТоварыДокумента;
    ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Номенклатура", "Номенклатура");
    Блокировка.Заблокировать(); // ОбработкаПроведения უკვე ტრანზაქციის შიგნით სრულდება

    // ჩაწერის შემდეგ ნაშთი უკვე შეიცავს ამ დოკუმენტის ხარჯს - ვეძებთ უარყოფით ნაშთს
    Движения.ТоварыНаСкладах.Записать();

    Недостача = УчетТоваровСервер.ОтрицательныеОстатки(Склад,
        ТоварыДокумента.ВыгрузитьКолонку("Номенклатура"));
    Для Каждого СтрокаНедостачи Из Недостача Цикл
        Отказ = Истина;
        Сообщение = Новый СообщениеПользователю;
        Сообщение.Текст = СтрШаблон(
            НСтр("ru = 'Недостаточно «%1» на складе: не хватает %2';
                |ka = 'საწყობში არ არის საკმარისი «%1»: აკლია %2'"),
            СтрокаНедостачи.Номенклатура, -СтрокаНедостачи.Остаток);
        Сообщение.Сообщить();
    КонецЦикла;

КонецПроцедуры

#КонецОбласти
```

Why it is correct under concurrency: the exclusive lock on the specific Склад + Номенклатура is taken **before** the movements are written and the balance is read, so a second posting of the same goods waits and cannot pass the check on the same units. The lock space is the register itself — `"РегистрНакопления.ТоварыНаСкладах"`; a virtual-table name is not a lock space. The platform already runs `ОбработкаПроведения` inside a transaction, so the lock is meaningful and is released when posting ends. Re-posting replaces the document's own movements (`Записать()` replaces the set by recorder), so the check never counts the previous issue. Non-real-time (back-dated) posting skips the check by design — it can leave a negative balance, which is what retrospective control (a negative-balance report) is for.

## 3. Managed form module — async "Check availability" command

```bsl
#Область ОбработчикиКомандФормы

&НаКлиенте
Асинх Процедура ПроверитьДоступность(Команда)

    // მსუბუქი შემოწმება კლიენტზე - სერვერთან მიმართვის გარეშე
    Если Объект.Товары.Количество() = 0 Тогда
        Ждать ПредупреждениеАсинх(НСтр("ru = 'Добавьте товары'; ka = 'დაამატეთ საქონელი'"));
        Возврат;
    КонецЕсли;

    // ერთი იაფი სერვერული გამოძახება, ფორმის კონტექსტის გადაცემის გარეშე
    Дефицит = ДефицитНаСервере(Объект.Склад, Объект.Товары);

    Если Дефицит.Количество() = 0 Тогда
        Ждать ПредупреждениеАсинх(НСтр("ru = 'Все товары в наличии'; ka = 'ყველა საქონელი მარაგშია'"));
        Возврат;
    КонецЕсли;

    // ასინქრონული კითხვა - მოდალური ფანჯრის გარეშე, ვებ-კლიენტშიც მუშაობს
    ТекстВопроса = СтрШаблон(НСтр("ru = 'Не хватает товаров по %1 позициям. Всё равно продолжить?';
        |ka = 'საქონელი არ ჰყოფნის %1 პოზიციაზე. მაინც გავაგრძელო?'"), Дефицит.Количество());
    Ответ = Ждать ВопросАсинх(ТекстВопроса, РежимДиалогаВопрос.ДаНет);
    Если Ответ <> КодВозвратаДиалога.Да Тогда
        Возврат;
    КонецЕсли;

    // ... სცენარის გაგრძელება ...

КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервереБезКонтекста
Функция ДефицитНаСервере(Знач Склад, Знач Товары)

    // Знач აუცილებელია: მის გარეშე პლატფორმა გამოძახების შემდეგ Объект.Товары-ს უკან გადაწერას
    // ცდილობს და შეცდომას იძლევა „Нельзя изменять поле, содержащее объект данных формы".
    // ТаблицаЗначений თხელ და ვებ კლიენტზე არ არსებობს - კლიენტს სტრუქტურების მასივს ვუბრუნებთ
    Дефицит = УчетТоваровСервер.ДефицитПоТоварам(Склад, Товары.Выгрузить());
    Результат = Новый Массив;
    Для Каждого СтрокаДефицита Из Дефицит Цикл
        Результат.Добавить(Новый Структура("Номенклатура, Требуется, Остаток",
            СтрокаДефицита.Номенклатура, СтрокаДефицита.Требуется, СтрокаДефицита.Остаток));
    КонецЦикла;
    Возврат Результат;

КонецФункции

#КонецОбласти
```

Why these choices:
- The command handler is `&НаКлиенте` and does only a cheap UI check, then makes **one** server call.
- That call is `&НаСервереБезКонтекста` because it needs no form attributes — only the warehouse and the lines — so the form is not transferred (the cheapest server call).
- Its parameters are **`Знач`**. A server call passes parameters by reference and copies them back after the call; copying back into `Объект.Товары` fails with «Нельзя изменять поле, содержащее объект данных формы».
- It returns an **array of structures**, not the `ТаблицаЗначений` the common module produced: the thin and web clients have no `ТаблицаЗначений`, and returning one fails with «Ошибка отображения типов: Отсутствует отображение для типа ValueTable».
- The dialogs use the **async** model (`Асинх`/`Ждать`, `ВопросАсинх`, `ПредупреждениеАсинх`) so nothing blocks the web client — modal `Вопрос()`/`Предупреждение()` would be wrong here.

## What this example demonstrates (map back to the standards)

- **Metadata** — register choice (balance kind) drives a cheap `.Остатки` read instead of summing documents.
- **Client/server** — no DB access on the client; `&НаСервереБезКонтекста` preferred; one round-trip; `Знач` parameters; only client-available types cross the boundary.
- **Concurrency** — managed exclusive lock on narrow dimensions in the register's lock space, taken before the write and the read, inside the posting transaction.
- **Queries** — one set-based query batch per question, virtual-table parameter filtering, the virtual table staged into a temp table before the join, indexes on the join field, only the needed columns.
- **Reuse** — balance logic lives once in a common module, called by both posting and the form.
- **Async + localization** — `Асинх/Ждать` dialogs and every user string via `НСтр` with a Georgian variant.

When you produce a solution, you don't need all of this every time — but a real posting-with-control feature looks like this, and the testing notes you give should target exactly these seams: a shortage of exactly one unit, issuing exactly the whole balance (must post and leave 0), two lines of the same item, re-posting an already posted document, concurrent posting of the same goods, back-dated posting, empty lines, a marked-for-deletion item. For an already posted document the form check still counts the document's earlier issue, so treat it as advisory — the binding check is the one in posting.
