# Integration & Data Exchange (Интеграция и обмен данными)

Reference for connecting 1C to the outside world and to other 1C bases: HTTP services, web (SOAP) services, outbound HTTP calls, JSON/XML/XDTO serialization, REST, and the EnterpriseData universal exchange format. Pick the mechanism deliberately in the analysis step and explain the choice in Georgian. Code uses Russian-syntax BSL by default.

## Contents
- Choosing an integration mechanism
- Inbound: HTTP services and web services
- Outbound: HTTPСоединение / HTTPЗапрос
- JSON: reading, writing, and object serialization
- XML and XDTO
- Exchange between 1C bases: EnterpriseData, Конвертация данных, exchange plans
- Idempotency, reliability, and security
- Where the heavy work belongs

## Choosing an integration mechanism

- **Another system calls 1C (1C is the server)** → publish an **HTTP service** (REST-style, recommended for new integrations — lightweight, cross-platform, JSON-friendly) or a **web service (SOAP/WS)** when the counterparty needs a WSDL contract. Both require a published web server (Apache/IIS) or the built-in mechanism.
- **1C calls another system (1C is the client)** → outbound `HTTPСоединение`/`HTTPЗапрос` (REST/JSON or any HTTP API), or a `WSСсылка`/`WSПрокси` proxy for a remote SOAP service.
- **1C ↔ 1C** → an **exchange plan (план обмена)** with the **EnterpriseData** universal format and **Конвертация данных 3** rules. Don't hand-roll XML between two 1C bases when the universal format already models the entities.
- **Bulk/offline file drop** → generate/parse a file (JSON/XML/CSV) on a schedule via a background job.

Prefer REST + JSON for new external integrations; reserve SOAP/WS for counterparties that mandate it.

## Inbound: HTTP services and web services

An **HTTP service** maps URL templates + methods (GET/POST/...) to handler functions in the service module. Keep handlers thin: validate input, delegate to a common module, return a typed response.

```bsl
// HTTP-сервис "ОбменЗаказами", шаблон "/orders", метод POST
Функция СоздатьЗаказПриPOST(Запрос)
    // ქართული: სხეულის წაკითხვა და დელეგირება — ლოგიკა საერთო მოდულშია
    ТелоПотока = Запрос.ПолучитьТелоКакСтроку();
    Результат = ИнтеграцияЗаказов.СоздатьЗаказИзJSON(ТелоПотока); // returns structure

    Ответ = Новый HTTPСервисОтвет(?(Результат.Успех, 201, 400));
    Ответ.Заголовки["Content-Type"] = "application/json; charset=utf-8";
    Ответ.УстановитьТелоИзСтроки(ИнтеграцияЗаказов.ОтветВJSON(Результат));
    Возврат Ответ;
КонецФункции
```

Guidance: authenticate every inbound call (the published service's user/rights, or a token you verify); return correct HTTP status codes (201 created, 400 bad request, 401/403, 409 conflict, 500); never let a raw platform exception leak to the caller — catch it, log it, return a clean error body. Do real work in a common module so the service module stays a thin adapter.

A **web service (SOAP)** is similar but contract-first (WSDL, XDTO types). Use it when the partner integration requires SOAP; otherwise an HTTP service is simpler.

## Outbound: HTTPСоединение / HTTPЗапрос

```bsl
Соединение = Новый HTTPСоединение("api.partner.com", 443, , , , 30, Новый ЗащищенноеСоединениеOpenSSL);
Запрос = Новый HTTPЗапрос("/v1/orders");
Запрос.Заголовки.Вставить("Authorization", "Bearer " + Токен);
Запрос.Заголовки.Вставить("Content-Type", "application/json");
Запрос.УстановитьТелоИзСтроки(ТелоJSON);

Попытка
    Ответ = Соединение.ОтправитьДляОбработки(Запрос); // POST
Исключение
    // ქართული: ქსელის შეცდომა — ჟურნალში ჩაწერა და გასაგები შეტყობინება
    ЗаписьЖурналаРегистрации(НСтр("ru = 'Интеграция: вызов API'; ka = 'ინტეგრაცია: API გამოძახება'"),
        УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
    ВызватьИсключение НСтр("ru = 'Сервис недоступен, повторите позже'; ka = 'სერვისი მიუწვდომელია, სცადეთ მოგვიანებით'");
КонецПопытки;

Если Ответ.КодСостояния >= 400 Тогда
    // ქართული: დაამუშავე HTTP შეცდომის სტატუსი ცალკე — 2xx არ არის წარმატების გარანტია
КонецЕсли;
```

Always set a timeout, use TLS (`ЗащищенноеСоединениеOpenSSL`) for https, check `КодСостояния` (a non-exception 4xx/5xx is still a failure), and run outbound calls **off the interactive path** (background job) when they can be slow — never inside a transaction.

## JSON: reading, writing, and object serialization

```bsl
// Parse
Чтение = Новый ЧтениеJSON;
Чтение.УстановитьСтроку(ТелоJSON);
Данные = ПрочитатьJSON(Чтение); // -> Соответствие/Массив of primitives
Чтение.Закрыть();

// Build
Запись = Новый ЗаписьJSON;
Запись.УстановитьСтроку();
ЗаписатьJSON(Запись, Данные);
Строка = Запись.Закрыть();
```

For 1C objects, `СериализаторXDTO` converts a value (structure, value table, even some platform objects) to/from JSON/XML in one step. Map external JSON to your own structures explicitly rather than assuming field names — external contracts change. Convert string keys to typed values (dates, numbers, references) defensively, with try/except around parsing of untrusted input.

## XML and XDTO

- **Fast streaming**: `ЧтениеXML`/`ЗаписьXML` for large documents you process node-by-node.
- **Typed/contract-based**: **XDTO** (фабрика XDTO) models XML against a schema — used by web services and by EnterpriseData. Use it when there is a formal schema; use plain `ЧтениеXML` for ad-hoc XML.
- `СериализаторXDTO.ЗаписатьXML(...)` serializes platform values; `ЗначениеИзСтрокиВнутр`/`ЗначениеВСтрокуВнутр` exist but are internal-format and not for external interop.

## Exchange between 1C bases: EnterpriseData, Конвертация данных, exchange plans

For 1C-to-1C (and 1C-to-partner-via-format) exchange, use the platform's purpose-built stack instead of bespoke code:

- **EnterpriseData** — a versioned universal XML format describing business entities (orders, goods, partners...). Both sides agree on a format version; neither needs to know the other's internal metadata.
- **Конвертация данных 3 (КД3)** — the tool where you define **conversion rules** between your configuration objects and the EnterpriseData format. Modern practice ships these rules as an **extension**, which is the most flexible, update-safe option.
- **Exchange plan (план обмена)** — defines the nodes, tracks **what changed since the last successful sync per node** (registration of changes), and carries message numbering.
- **Message structure** — exchange messages are XML with a `<Header>` (containing a `<Confirmation>` receipt with the last received/sent message numbers) and a `<Body>` (the changed entities in EnterpriseData). The confirmation numbers are how each side knows what the other has already accepted.

Choose this route whenever the data being exchanged maps onto recognizable business entities — it gives you change tracking, restartability, and version tolerance for free.

## Idempotency, reliability, and security

- **Idempotency.** Assume messages can be re-delivered. Key inbound records by an external id and upsert (find-or-create) rather than blindly inserting, so a retry does not create duplicates. Exchange-plan message numbering/confirmation gives this for 1C↔1C; for external APIs, store the external id on your object.
- **Restartability.** Process exchange in a background job; record progress so an interrupted run resumes instead of restarting. Commit in reasonable batches, not one giant transaction.
- **Validation & security.** Treat all inbound data as untrusted: validate types and references, wrap parsing in try/except, and never build queries by concatenating incoming strings — use parameters. Authenticate callers; store tokens/passwords in safe storage (`БезопасноеХранилище`), never hardcoded.
- **Logging.** Log every exchange with enough context (direction, node, message number, counts) to diagnose a failure, and surface user-facing errors via `НСтр` with a Georgian variant.

## Where the heavy work belongs

Integration calls are slow and unpredictable. Run them on the **server**, **off the interactive thread** (background job — see `platform-mechanisms.md`), **outside transactions**, and with explicit timeouts and error handling. The interactive client should at most trigger the job and poll for its result.
