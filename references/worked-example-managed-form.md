# Worked Example: End-to-End Managed Form + Posting

A single, coherent example that shows the skill's principles working **together**: metadata choice, client/server separation, a server-without-context call, document posting with a managed lock and balance control, set-based queries via virtual tables, the async client model, `НСтр` localization, and exception logging. Use it as a template for how the pieces fit — adapt, don't copy blindly.

## Scenario

"When a goods-issue document (`РеализацияТоваров`) is posted, it must not drive warehouse stock negative. The user also wants a *Check availability* button on the form that reports shortages before they try to post."

## Metadata (analysis step output, normally written in Georgian)

- **Документ «РеализацияТоваров»** — the business event; lines in a tabular section «Товары» (Номенклатура, Количество).
- **Регистр накопления «ТоварыНаСкладах»** (balance kind) — dimensions Склад, Номенклатура; resource Количество. Stock lives here; posting writes Расход movements.
- Current stock is read from the `.Остатки` virtual table — never recomputed from documents.
- Concurrency: two users posting issues for the same goods must not both pass the balance check on the same units → the posting transaction takes a **managed exclusive lock** on the touched register dimensions before reading balances.

## 1. Common module «УчетТоваровСервер» (server)

Reusable, context-free balance logic lives here so both posting and the form reuse it — no duplication, no DB access on the client.

```bsl
// Общий модуль "УчетТоваровСервер": флаги Сервер (+ Вызов сервера, чтобы форма могла вызвать)

// ქართული: აბრუნებს დეფიციტის ცხრილს მითითებული საწყობისთვის ერთი მოთხოვნით (НЕ ციკლში!).
// СписокТоваров — ТаблицаЗначений с колонками Номенклатура, Количество.
Функция ДефицитПоТоварам(Склад, СписокТоваров) Экспорт

    Запрос = Новый Запрос;
    Запрос.Текст =
        "ВЫБРАТЬ Номенклатура, Количество ПОМЕСТИТЬ ВтТребуется
        |ИЗ &Требуется КАК Т
        |ИНДЕКСИРОВАТЬ ПО Номенклатура
        |;
        |ВЫБРАТЬ
        |   Т.Номенклатура КАК Номенклатура,
        |   Т.Количество КАК Требуется,
        |   ЕСТЬNULL(Ост.КоличествоОстаток, 0) КАК Остаток
        |ИЗ ВтТребуется КАК Т
        |ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ТоварыНаСкладах.Остатки(
        |       , Склад = &Склад
        |         И Номенклатура В (ВЫБРАТЬ Номенклатура ИЗ ВтТребуется)) КАК Ост
        |   ПО Ост.Номенклатура = Т.Номенклатура
        |ГДЕ Т.Количество > ЕСТЬNULL(Ост.КоличествоОстаток, 0)";

    Запрос.УстановитьПараметр("Требуется", СписокТоваров);
    Запрос.УстановитьПараметр("Склад", Склад);

    Возврат Запрос.Выполнить().Выгрузить(); // Номенклатура, Требуется, Остаток
КонецФункции
```

Notes: one set-based query (no query-in-a-loop); the filter is **inside** the virtual-table parameters; a temp table stages the requested goods and is indexed for the join; only needed columns are selected.

## 2. Object module of «РеализацияТоваров» — posting with lock + balance control

```bsl
Процедура ОбработкаПроведения(Отказ, РежимПроведения)
    // ქართული: მოძრაობების ფორმირება + ნაშთის კონტროლი ბლოკირებით (პროაქტიული კონტროლი)

    // 1) Формируем движения набором (не построчно с запросами)
    Движения.ТоварыНаСкладах.Записывать = Истина;
    Для Каждого СтрокаТовара Из Товары Цикл
        Движение = Движения.ТоварыНаСкладах.Добавить();
        Движение.ВидДвижения  = ВидДвиженияНакопления.Расход;
        Движение.Период       = Дата;
        Движение.Склад        = Склад;
        Движение.Номенклатура = СтрокаТовара.Номенклатура;
        Движение.Количество   = СтрокаТовара.Количество;
    КонецЦикла;

    // 2) Контроль остатков нужен только при оперативном проведении
    Если РежимПроведения = РежимПроведенияДокумента.Оперативный Тогда

        ТоварыТаблица = Товары.Выгрузить(); // ТаблицаЗначений: Номенклатура, Количество, ...

        // Блокируем затрагиваемые измерения регистра ДО чтения остатков
        Блокировка = Новый БлокировкаДанных;
        ЭлементБлокировки = Блокировка.Добавить("РегистрНакопления.ТоварыНаСкладах.Остатки");
        ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
        ЭлементБлокировки.УстановитьЗначение("Склад", Склад);
        ЭлементБлокировки.ИсточникДанных = ТоварыТаблица; // ограничить набором номенклатуры из ТЧ
        ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Номенклатура", "Номенклатура");
        Блокировка.Заблокировать(); // мы уже внутри транзакции проведения

        // Записать движения, чтобы они учлись в остатках, затем проверить
        Движения.ТоварыНаСкладах.Записать();

        Дефицит = УчетТоваровСервер.ДефицитПоТоварам(Склад, ТоварыТаблица);
        Если Дефицит.Количество() > 0 Тогда
            Отказ = Истина;
            Для Каждого СтрокаДефицита Из Дефицит Цикл
                Сообщение = Новый СообщениеПользователю;
                Сообщение.Текст = СтрШаблон(
                    НСтр("ru = 'Недостаточно «%1»: требуется %2, остаток %3';
                        |ka = 'არ არის საკმარისი «%1»: საჭიროა %2, ნაშთი %3'"),
                    СтрокаДефицита.Номенклатура, СтрокаДефицита.Требуется, СтрокаДефицита.Остаток);
                Сообщение.Сообщить();
            КонецЦикла;
        КонецЕсли;

    КонецЕсли;
КонецПроцедуры
```

Why it is correct under concurrency: the exclusive lock on the specific Склад + Номенклатура is taken **before** the balance read, so a second concurrent posting waits and cannot pass the same check on the same units. The platform already runs `ОбработкаПроведения` inside a transaction, so the managed lock is meaningful and is released when posting ends. Non-real-time (back-dated) posting skips the live check by design.

## 3. Managed form module — async "Check availability" command

```bsl
&НаКлиенте
Асинх Процедура ПроверитьДоступность(Команда)
    // ქართული: ჯერ მსუბუქი UI-შემოწმება კლიენტზე
    Если Объект.Товары.Количество() = 0 Тогда
        Ждать ПредупреждениеАсинх(НСтр("ru = 'Добавьте товары'; ka = 'დაამატეთ საქონელი'"));
        Возврат;
    КонецЕсли;

    // Дешёвый серверный вызов без контекста: передаём только нужные значения
    Дефицит = ДефицитНаСервере(Объект.Склад, Объект.Товары);

    Если Дефицит.Количество() = 0 Тогда
        Ждать ПредупреждениеАсинх(НСтр("ru = 'Всё в наличии'; ka = 'ყველაფერი მარაგშია'"));
    Иначе
        // ასინქრონული კითხვა — მოდალური ფანჯრის გარეშე, ვებ-კლიენტისთვისაც ვარგისი
        Ответ = Ждать ВопросАсинх(
            СтрШаблон(НСтр("ru = 'Дефицит по %1 позициям. Всё равно продолжить?';
                |ka = 'დეფიციტი %1 პოზიციაზე. მაინც გავაგრძელო?'"), Дефицит.Количество()),
            РежимДиалогаВопрос.ДаНет);
        Если Ответ = КодВозвратаДиалога.Да Тогда
            // ... продолжить сценарий ...
        КонецЕсли;
    КонецЕсли;
КонецПроцедуры

&НаСервереБезКонтекста
Функция ДефицитНаСервере(Склад, ТаблицаТоваров)
    // ქართული: form-контексти არ გვჭირდება — ამიტომ БезКонтекста (იაფი გამოძახება)
    Возврат УчетТоваровСервер.ДефицитПоТоварам(Склад, ТаблицаТоваров.Выгрузить());
КонецФункции
```

Why these directives: the command handler is `&НаКлиенте` and does only a cheap UI check, then makes **one** server call. That call is `&НаСервереБезКонтекста` because it needs no form attributes — only the warehouse and the lines — so the form is not transferred (the cheapest server call). The dialogs use the **async** model (`Асинх`/`Ждать`, `ВопросАсинх`, `ПредупреждениеАсинх`) so nothing blocks the web client — modal `Вопрос()`/`Предупреждение()` would be wrong here.

## What this example demonstrates (map back to the standards)

- **Metadata** — register choice (balance kind) drives a cheap `.Остатки` read instead of summing documents.
- **Client/server** — no DB access on the client; `&НаСервереБезКонтекста` preferred; a single round-trip.
- **Concurrency** — managed exclusive lock on narrow dimensions, taken before the read, inside the posting transaction.
- **Queries** — one set-based query, virtual-table parameter filtering, temp table + index, only needed columns.
- **Reuse** — balance logic lives once in a common module, called by both posting and the form.
- **Async + localization** — `Асинх/Ждать` dialogs and every user string via `НСтр` with a Georgian variant.

When you produce a solution, you don't need all of this every time — but a real posting-with-control feature looks like this, and the testing notes you give should target exactly these seams (empty lines, concurrent posting of the same goods, back-dated posting, a shortage of exactly one unit, a marked-for-deletion item).
