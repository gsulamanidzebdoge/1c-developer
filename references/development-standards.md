# 1C Development Standards (Стандарты разработки 1С)

Reference for writing module code that conforms to the official 1C standards and the conventions of the Standard Subsystems Library (БСП / SSL). Code examples use Russian-syntax BSL by default; mirror English syntax if the user's codebase uses it.

## Contents
- Module types and where logic belongs
- Compilation directives (client/server context)
- Common module flags
- Module structure and regions
- Naming conventions
- Variables, parameters, and explicitness
- Exception handling and logging
- Localizable strings with НСтр (including Georgian)
- Avoiding hardcoded values
- Asynchronous client model (Асинх/Ждать) and modal deprecation
- Reusing the platform and БСП
- Common БСП modules cheat sheet
- Development environment: Configurator vs 1C:EDT, platform version

## Module types and where logic belongs

| Module | Purpose | Typical context |
|---|---|---|
| Модуль формы (Form module) | Form behavior, UI events | client + server directives |
| Модуль объекта (Object module) | Object logic: ОбработкаПроведения, ПередЗаписью, ОбработкаЗаполнения | server |
| Модуль менеджера (Manager module) | Object-type-level logic, shared helpers for that object | server |
| Общий модуль (Common module) | Reusable cross-object logic | flags decide context |
| Модуль сеанса (Session module) | Session parameters setup | server |

Put business logic in object/manager/common modules, not in form modules. Form modules should orchestrate UI and delegate real work to the server side. This keeps logic reusable and testable.

## Compilation directives (client/server context)

Every procedure/function in a form module must declare its execution context. Choosing the right one is both a correctness and a performance decision.

- `&НаКлиенте` (AtClient) — runs in the thin/web client. Handles user interaction. **No database access.** Use for event handlers like `ПриИзменении`, command handlers that then call the server.
- `&НаСервере` (AtServer) — runs on the server *with the full form context transferred both ways*. The most expensive call. Use only when you genuinely need to read/modify form attributes server-side.
- `&НаСервереБезКонтекста` (AtServerNoContext) — runs on the server **without** transferring form context. Much cheaper. **Prefer this** for any server work that can take its inputs as parameters and return results. Cannot touch `ЭтотОбъект`/form attributes directly.
- `&НаКлиентеНаСервереБезКонтекста` — compiled for both client and server-without-context; for small shared helpers (e.g., formatting) usable on either side.

Pattern: a client command handler does a quick UI check, calls a `&НаСервереБезКонтекста` function passing only the needed values, then updates the UI with the result.

```bsl
&НаКлиенте
Процедура РассчитатьИтог(Команда)
    Если НЕ ЗначениеЗаполнено(Объект.Контрагент) Тогда
        // ქართული: ჯერ უნდა შეივსოს კონტრაგენტი
        ПоказатьПредупреждение(, НСтр("ru = 'Заполните контрагента'; ka = 'შეავსეთ კონტრაგენტი'"));
        Возврат;
    КонецЕсли;
    Объект.СуммаИтог = РассчитатьИтогНаСервере(Объект.Контрагент, Объект.Дата);
КонецПроцедуры

&НаСервереБезКонтекста
Функция РассчитатьИтогНаСервере(Контрагент, Дата)
    // ქართული: სერვერული გამოთვლა კონტექსტის გადატანის გარეშე — იაფი გამოძახება
    Возврат РасчетыСервер.ИтогПоКонтрагенту(Контрагент, Дата);
КонецФункции
```

## Common module flags

A common module's checkboxes define its context and behavior. Combine deliberately:

- **Клиент (управляемое приложение)** — available on the client.
- **Сервер** — available on the server.
- **Вызов сервера** — client code may call its exported procedures (server call). Keep these modules focused; a server-call module is an API surface.
- **Внешнее соединение** — available via external connection / background.
- **Привилегированный** — runs with full rights, ignoring access restrictions. Use sparingly and only where justified; it bypasses RLS.
- **Повторное использование возвращаемых значений** (cached) — caches results per call/session. Excellent for rarely-changing lookups; never use for data that changes within the operation.

Convention: pure server logic → Сервер only. Client-callable API → Сервер + Вызов сервера. Shared client/server utilities → Клиент + Сервер.

## Module structure and regions

Organize modules with `#Область`/`#КонецОбласти` in the standard order so any developer can navigate them. A common managed-form module order:

```bsl
#Область ОбработчикиСобытийФормы
// ПриСозданииНаСервере, ПриОткрытии, ПередЗаписью ...
#КонецОбласти

#Область ОбработчикиСобытийЭлементовШапкиФормы
#КонецОбласти

#Область ОбработчикиСобытийЭлементовТаблицыФормы
#КонецОбласти

#Область ОбработчикиКомандФормы
#КонецОбласти

#Область СлужебныеПроцедурыИФункции
// private helpers
#КонецОбласти
```

For object/common modules: public (exported) interface first, then private helpers, each in its region. Exported procedures intended as the module's API carry a documenting comment describing parameters and return value.

## Naming conventions

- Identifiers in the configuration's primary language (typically Russian), CamelCase for procedures/variables: `РассчитатьСебестоимость`, `ТекущаяДата`.
- Names should read as meaningful phrases; avoid abbreviations and single letters except trivial loop counters.
- Boolean names read as predicates: `ЭтоНовый`, `ПроведениеРазрешено`.
- Export procedures forming an API get clear, stable names — renaming later breaks callers.

## Variables, parameters, and explicitness

- Declare module-level variables with `Перем` at the top; declare local intent clearly.
- Pass data through parameters rather than relying on global/module state where practical.
- Keep procedures single-purpose and short. If a procedure does three things, split it.
- Avoid `Выполнить()` and `Вычислить()` unless there is truly no declarative alternative — they block static analysis, hurt performance, and are an injection risk if fed dynamic strings.

## Exception handling and logging

Wrap operations that can fail (queries against external systems, file/HTTP work, transactions, type conversions on user input) and handle the error meaningfully:

```bsl
Попытка
    НачатьТранзакцию();
    // ... работа ...
    ЗафиксироватьТранзакцию();
Исключение
    ОтменитьТранзакцию();
    ИнфОшибки = ИнформацияОбОшибке();
    ЗаписьЖурналаРегистрации(
        НСтр("ru = 'Проведение документа'; ka = 'დოკუმენტის გატარება'"),
        УровеньЖурналаРегистрации.Ошибка, , ,
        ПодробноеПредставлениеОшибки(ИнфОшибки));
    ВызватьИсключение НСтр("ru = 'Не удалось провести документ. Подробности в журнале регистрации.';
        |ka = 'დოკუმენტის გატარება ვერ მოხერხდა. დეტალები იხილეთ რეგისტრაციის ჟურნალში.'");
КонецПопытки;
```

Rules: always roll back the transaction in the handler; log technical detail via `ЗаписьЖурналаРегистрации`; show the user a clear, localized, non-technical message; never leave an empty `Исключение` block that hides the failure.

## Localizable strings with НСтр (including Georgian)

Every user-facing literal goes through `НСтр` (NStr) with language codes, so the same configuration serves Russian, Georgian, English, etc.:

```bsl
Сообщение = НСтр("ru = 'Документ проведён'; ka = 'დოკუმენტი გატარდა'; en = 'Document posted'");
```

Use the multi-line `|` continuation for longer strings. This is the mechanism that lets the 1C UI speak Georgian — relying on it is what makes "Georgian UI support" real rather than a one-off hardcode.

## Avoiding hardcoded values

Replace magic literals with first-class metadata:

- Statuses/types → **Перечисления** (enumerations), compared as `Перечисления.СтатусыЗаказов.Выполнен`.
- Fixed reference items → **предопределённые элементы** (predefined items), accessed by name, never by a hardcoded code/GUID.
- Tunable settings → **Константы** or settings objects, not literals in code.
- Repeated values within a routine → a named variable computed once.

## Asynchronous client model (Асинх/Ждать) and modal deprecation

The managed/web client **cannot block the UI thread**, so the old synchronous interactive methods — `Вопрос()`, `Предупреждение()`, `ВвестиЧисло/ВвестиСтроку/ВвестиДату()`, `ОткрытьФормуМодально()` — are **deprecated** and throw or misbehave in the web client. Never write them in new client code. There are two non-blocking replacements; prefer the second for anything new:

1. **Callback style (`ОписаниеОповещения`)** — the original non-modal mechanism: you pass a handler that the platform calls when the user responds. Still valid, but it fragments logic across procedures.
2. **Async/await (`Асинх` / `Ждать`, platform 8.3.18+)** — the modern, preferred style. Mark the procedure/function `Асинх`; call an async method with `Ждать` and write linear code. An `Асинх` function returns an `Обещание` (Promise); `Ждать` suspends until it resolves. Use the `*Асинх` method variants: `ВопросАсинх`, `ПредупреждениеАсинх`, `ОткрытьФормуАсинх`, `ПоказатьВводЧислаАсинх`, etc. (English syntax: `Async` / `Await`.)

```bsl
// ❌ deprecated for the web client — blocks the UI
Ответ = Вопрос(НСтр("ru = 'Провести документ?'; ka = 'გავატარო დოკუმენტი?'"), РежимДиалогаВопрос.ДаНет);
Если Ответ = КодВозвратаДиалога.Да Тогда // ...

// ✅ modern: Асинх + Ждать — линейно, без блокировки интерфейса
&НаКлиенте
Асинх Процедура ПровестиВыполнить(Команда)
    Ответ = Ждать ВопросАсинх(
        НСтр("ru = 'Провести документ?'; ka = 'გავატარო დოკუმენტი?'"),
        РежимДиалогаВопрос.ДаНет);
    Если Ответ = КодВозвратаДиалога.Да Тогда
        // ქართული: დადასტურების შემდეგ — სერვერული გამოძახება
        ПровестиНаСервере();
    КонецЕсли;
КонецПроцедуры
```

Rules: a procedure that uses `Ждать` must itself be `Асинх`; command handlers can be `Асинх`. This is a **client/UI** concern only — server code runs synchronously, so don't sprinkle `Асинх` on server methods. When the user's platform is older than 8.3.18, fall back to the callback style. If you see modal calls while reviewing code, flag them (see `code-review-checklist.md`).

## Reusing the platform and БСП (SSL)

Before writing a helper, check whether the platform or Библиотека стандартных подсистем already provides it. Common reusable areas: `ОбщегоНазначения` (CommonModule) for shared utilities (e.g., `ОбщегоНазначения.ЗначениеРеквизитаОбъекта`), date/number formatting, table-to-query conversions, user/rights helpers, file and email subsystems. Reusing БСП keeps behavior consistent with the rest of the configuration and reduces maintenance.

## Common БСП modules cheat sheet

The exact procedure names and module set depend on the deployed БСП (SSL) version — verify against the configuration in hand — but these are the modules you reach for most. Prefer them over re-implementing equivalents.

| Module | Use for |
|---|---|
| `ОбщегоНазначения` / `...Клиент` / `...КлиентСервер` | Everyday utilities: `ЗначениеРеквизитаОбъекта`, `ЗначенияРеквизитовОбъекта` (batch — avoids per-attribute reads), `СообщитьПользователю`, structure/table helpers, current-date helpers |
| `ДлительныеОперации` / `ДлительныеОперацииКлиент` | Run heavy work in a background job with a progress window (see `platform-mechanisms.md`) |
| `Пользователи` / `ПользователиКлиент` | Current user, admin checks, rights |
| `УправлениеДоступом` | Access groups, profiles, RLS value sets — work through this, not ad-hoc role logic |
| `РаботаСФайлами` / `ХранилищеНастроек` helpers | Files, temp storage, saved form/user settings |
| `ЭлектроннаяПочта` / `ОтправкаСМS` | Outbound email / SMS |
| `ОбновлениеИнформационнойБазы` | Data-fill handlers that run on configuration update |
| `СтроковыеФункцииКлиентСервер` | String formatting beyond `СтрШаблон` (e.g., parametrized templates) |

When in doubt whether БСП covers something, assume it might and check — re-implementing a subsystem function is a common, avoidable mistake.

## Development environment: Configurator vs 1C:EDT, platform version

- **IDE.** Two environments produce the *same* BSL: the classic **Конфигуратор (Designer)** and the Eclipse-based **1С:EDT**, which stores the configuration as text (Git-friendly) and adds modern refactoring/validation. Teams increasingly develop in EDT and deploy to the same platform. The choice of IDE never changes the language or the standards — only the tooling. If the user mentions EDT, Git workflows, or a text-format export, you are in an EDT context; otherwise assume Designer.
- **Platform version.** Target the user's actual platform: don't use a feature newer than they run. Async `Асинх/Ждать` needs **8.3.18+**; current releases as of 2026 are **8.3.26 / 8.3.27**. Assume the **managed application** (управляемое приложение) — ordinary (обычные) forms and the thick-client-only model are legacy; only use them if the user's configuration explicitly does. When a feature you propose has a version floor, say so in Georgian so the user can confirm their platform supports it.
