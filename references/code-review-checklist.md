# Code Review Checklist (Ревью существующего кода)

Use this when the user asks you to **review, audit, or critique existing 1C code** (a module, a query, a posting handler, a PR-style diff) rather than write new code. Reviewing is a distinct mode from building: you start from someone else's code, find what is wrong or risky, and report it constructively. All findings are written in fluent Georgian; quote the relevant code and propose a concrete fix.

## Review workflow

1. **Understand intent first.** Restate, in Georgian, what the code is meant to do and in what context it runs (module type, client/server, called from where, data volumes). If intent is unclear and it changes your judgment, ask one focused question.
2. **Pass through the dimensions below**, top to bottom — correctness first, then concurrency, performance, standards, security, localization, maintainability. Read the relevant reference file when a dimension needs depth.
3. **Report findings grouped by severity** (see format). For each: what, why it matters, and a concrete corrected snippet.
4. **Acknowledge what's done well** briefly — review is not only fault-finding, and it helps the user trust the critique.

## Severity levels

- 🔴 **კრიტიკული (Critical)** — data corruption, wrong results, security hole, or a multi-user race. Must fix before shipping.
- 🟠 **მნიშვნელოვანი (Major)** — real performance problem, missing error handling, standards violation that will bite later.
- 🟡 **მცირე (Minor)** — readability, naming, small inefficiency, missing comment.
- 🟢 **რეკომენდაცია (Suggestion)** — optional improvement, alternative approach.

## Review dimensions

### 1. Correctness & business logic
- Does the code actually implement the stated rule? Off-by-one, wrong sign on register movements (Приход/Расход), wrong comparison operator?
- Are empty/`NULL`/`Неопределено` results handled? Is `ЗначениеЗаполнено` checked before use?
- Marked-for-deletion or non-posted references treated correctly?
- Date boundaries (begin/end of period, `КонецДня`) correct?

### 2. Client/server architecture
- Is there **any database access on the client** (`&НаКлиенте`)? That is always wrong — flag it.
- Is `&НаСервереБезКонтекста` used where form context isn't needed (cheaper), instead of `&НаСервере`?
- Are there server round-trips **inside a loop**? Batch them into one call.
- Is whole-object data shuttled across the client/server boundary when a few values would do?

### 3. Concurrency, transactions, posting
- Read-then-write on balances **without a managed lock** → race condition (🔴). See `locking-transactions-posting.md`.
- Every `НачатьТранзакцию` paired with commit/rollback on all paths? Rollback in the exception handler?
- Locks acquired in a consistent order (deadlock risk)? Lock scope narrowed to the dimensions touched?
- Posting (`ОбработкаПроведения`): movements formed set-based and idempotently? Balance control matches the chosen proactive/retrospective strategy?
- Slow/external/interactive work inside a transaction → flag it.

### 4. Queries & performance
- **Query inside a loop** (запрос в цикле) → the number-one issue (🔴/🟠). Rewrite set-based. See `query-language-and-optimization.md`.
- Balances/turnovers recomputed from documents instead of virtual tables?
- Filters in the outer `ГДЕ` that belong in virtual-table parameters?
- `ПОДОБНО '%...'` with a leading wildcard; functions wrapped around indexed fields; `ОБЪЕДИНИТЬ` where `ОБЪЕДИНИТЬ ВСЕ` suffices; selecting unneeded columns?
- Heavy dynamic-list queries degrading list forms?

### 5. Standards & maintainability
- Module organized with `#Область` regions in standard order?
- Hardcoded magic values (statuses, codes, GUIDs) instead of Перечисления / предопределённые элементы / Константы?
- `Выполнить()` / `Вычислить()` on dynamic strings (static-analysis, performance, and injection risk)?
- Procedures single-purpose and reasonably short? Names meaningful?
- Platform/БСП method re-implemented by hand instead of reused?

### 6. Error handling & logging
- Risky operations wrapped in `Попытка ... Исключение`? No **empty** `Исключение` block silently swallowing failures (🔴/🟠)?
- Technical detail logged via `ЗаписьЖурналаРегистрации` with `ПодробноеПредставлениеОшибки`, and a clean message shown to the user?

### 7. Security & access
- Query text built by concatenating user/external input instead of `УстановитьПараметр`? → injection (🔴).
- Unjustified privileged mode bypassing RLS?
- `РАЗРЕШЕННЫЕ` used appropriately when RLS is in play?
- Secrets/tokens hardcoded instead of `БезопасноеХранилище`?

### 8. Localization & UX
- User-facing strings hardcoded instead of `НСтр(...)` with a `ka` variant?
- Modal/synchronous dialogs (`Предупреждение`, `Вопрос`) in code meant for the web client, instead of the async `ПоказатьПредупреждение`/`ПоказатьВопрос` or `Асинх/Ждать` model? See `development-standards.md`.

### 9. Extensions (if reviewing an extension)
- `&Вместо` used where `&После`/`&Перед`/`&ИзменениеИКонтроль` would be safer?
- Business logic stuffed into a borrowed module instead of the extension's own module?
- See `configuration-extensions.md`.

## Reporting format

Structure the review in Georgian like this:

```
## შეფასების შეჯამება
<2–3 წინადადება: საერთო მდგომარეობა, მთავარი რისკი>

## კრიტიკული საკითხები 🔴
1. <პრობლემა> — <რატომ არის საშიში>
   <კოდის ციტატა>
   შესწორება: <გასწორებული ფრაგმენტი>

## მნიშვნელოვანი 🟠
...

## მცირე / რეკომენდაციები 🟡🟢
...

## რა არის კარგად გაკეთებული ✅
...
```

Keep it specific to the reviewed code — quote the actual lines, give the actual fix, never generic advice. If the code is large, prioritize: lead with the few findings that matter most rather than an exhaustive flat list.
