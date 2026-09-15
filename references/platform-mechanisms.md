# Platform Mechanisms (Механизмы платформы)

Reference for high-leverage platform features beyond CRUD and posting: background & scheduled jobs, long-running operations on managed forms, functional options, event subscriptions, dynamic lists, and access rights / RLS. Reach for the platform mechanism instead of re-implementing it. Code uses Russian-syntax BSL by default.

## Contents
- Background and scheduled jobs (фоновые / регламентные задания)
- Long operations on a managed form (ДлительныеОперации, БСП)
- Functional options (функциональные опции)
- Event subscriptions (подписки на события)
- Dynamic lists (динамический список)
- Access rights, roles, and RLS design

## Background and scheduled jobs (фоновые / регламентные задания)

The platform rule of thumb: **any server call that can run longer than ~8 seconds in a normal scenario should run asynchronously in a background job**, not block the user's session. Two kinds:

- **Фоновое задание (background job)** — a one-off task launched on demand (e.g., a heavy recalculation the user started).
- **Регламентное задание (scheduled job)** — a recurring task on a schedule (nightly close, periodic sync). Always pair it with a **predefined** scheduled job and run the body in a common module so it is testable on demand.

```bsl
// запуск фоновой задачи (low-level): менеджер ФоновыеЗадания, метод Выполнить
Параметры = Новый Массив;
Параметры.Добавить(ПараметрыОперации);
ФоновыеЗадания.Выполнить("МойМодуль.ПересчитатьСебестоимость", Параметры, ,
    НСтр("ru = 'Пересчёт себестоимости'; ka = 'თვითღირებულების გადაანგარიშება'"));
```

Prefer the БСП `ДлительныеОперации` wrapper (next section) for anything user-facing; reach for the low-level `ФоновыеЗадания`/`РегламентныеЗадания` managers when you need direct control.

Scheduled-job discipline: make the body **idempotent and restartable** (it may overlap or be retried); guard against concurrent runs of the same job; keep each run's transaction scope small; log start/finish/counts via `ЗаписьЖурналаРегистрации`; never assume an interactive user or session parameters — a job runs without a UI.

## Long operations on a managed form (ДлительныеОперации, БСП)

For an interactive heavy action, don't freeze the form. Use the БСП **ДлительныеОперации** subsystem: start the work in a background job on the server, then let the client poll for completion and progress (the familiar progress window). This is the standard pattern in modern typical configurations.

```bsl
&НаСервере
Процедура ЗапуститьРасчетНаСервере()
    // ქართული: ფონური დავალების გაშვება БСП-ს ДлительныеОперации-ით
    ПараметрыВыполнения = ДлительныеОперации.ПараметрыВыполненияВФоне(УникальныйИдентификатор);
    ПараметрыВыполнения.НаименованиеФоновогоЗадания = НСтр("ru = 'Расчёт себестоимости'; ka = 'თვითღირებულების გამოთვლა'");
    ЗаданиеОписание = ДлительныеОперации.ВыполнитьВФоне("Расчеты.ПересчитатьСебестоимость", ПараметрыМетода, ПараметрыВыполнения);
КонецПроцедуры

&НаКлиенте
Процедура ПослеЗапускаДлительнойОперации(Задание) Экспорт
    // ожидаем завершения; платформа покажет индикатор
    ОжиданиеЗавершения = ДлительныеОперацииКлиент.ПараметрыОжиданияЗавершения(ЭтотОбъект);
    ДлительныеОперацииКлиент.ОжидатьЗавершение(Задание, Новый ОписаниеОповещения("ПриЗавершенииРасчета", ЭтотОбъект), ОжиданиеЗавершения);
КонецПроцедуры
```

Report progress from inside the job with `ДлительныеОперации.СообщитьПрогресс`, read it on the client with `ПрочитатьПрогресс`. Surface the final result (or error) to the user with a clear localized message.

## Functional options (функциональные опции)

A **функциональная опция** toggles whole pieces of functionality (objects, attributes, commands, form items) on/off based on a stored value (often a Константа). Use them to ship optional features cleanly instead of scattering `Если НастройкаВключена Тогда` across the code:

- Tie UI elements, attributes, and commands to an option so they appear only when the option is on.
- Read the current state in code with `ПолучитьФункциональнуюОпцию("ИмяОпции")`.
- Combine with параметры функциональных опций to vary behavior by a key (e.g., per organization).

This keeps optional functionality declarative and avoids dead UI for customers who don't use it.

## Event subscriptions (подписки на события)

A **подписка на события** attaches a handler in a common (server) module to events of many objects at once (e.g., `ПередЗаписью` of every document of certain types) **without** editing each object module. Ideal for cross-cutting rules (audit stamping, denormalized field maintenance) and for extensions that must react to base objects.

```bsl
// общий модуль "ПодпискиСобытий", серверный
Процедура ПроставитьАвтораПередЗаписью(Источник, Отказ) Экспорт
    // ქართული: ერთიანი წესი — ავტორის ჩაწერა ყველა გამოწერილ ობიექტზე
    Если Источник.ЭтоНовый() Тогда
        Источник.Автор = Пользователи.ТекущийПользователь();
    КонецЕсли;
КонецПроцедуры
```

Keep subscription handlers fast and side-effect-light (they run on the write path of many objects), make their object set explicit, and beware ordering assumptions when several subscriptions cover the same event.

## Dynamic lists (динамический список)

A **динамический список** is the data source behind list forms — it reads incrementally and only the visible window, which is what makes large lists responsive. Customize it well:

- Set a custom query (Произвольный запрос) only when you need joins/computed columns; otherwise the main-table mode is fastest.
- Keep the list query lean and **index-friendly** — the same query rules as in `query-language-and-optimization.md` apply (no functions on indexed fields, filter narrowly, avoid leading-`%` `ПОДОБНО`). A heavy dynamic-list query degrades scrolling for everyone.
- Use list **settings/filters/conditional appearance** declaratively rather than reloading data in code.
- Don't fetch the whole list into memory to process it — that defeats the incremental reading; do set-based work in a separate query/background job instead.

## Access rights, roles, and RLS design

Design the security model deliberately, not as an afterthought:

- **Roles (роли)** grant object- and right-level permissions (read/add/change/delete, plus action rights). Compose small, purpose-named roles and assign them via profiles (БСП «Управление доступом») rather than one giant role per user.
- **RLS (ограничение доступа на уровне записей)** restricts *which rows* a role can see/change (e.g., a manager sees only their organization's documents). Define restriction templates and keep them simple — complex RLS is a top performance and correctness risk.
- In queries that run under RLS, use `ВЫБРАТЬ РАЗРЕШЕННЫЕ` to silently skip forbidden rows; use a **privileged** context (privileged common module, or `УстановитьПривилегированныйРежим(Истина)`) only where a system operation legitimately must bypass restrictions — and scope it as narrowly as possible.
- Check rights in code with `ПравоДоступа(...)` / `ОбщегоНазначения` helpers before offering an action, so the UI doesn't present commands the user cannot execute.
- When using the БСП access-management subsystem, work through its API (access groups, profiles, access value sets) instead of writing ad-hoc role logic — it keeps behavior consistent and auditable.

Always weigh RLS cost: every restricted query carries the restriction condition, so over-broad or function-heavy RLS templates can dominate query time. Model access on indexed dimensions (organization, division) where possible.
