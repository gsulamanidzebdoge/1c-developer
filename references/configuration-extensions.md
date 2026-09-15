# Configuration Extensions (Расширения конфигурации)

How to customize a vendor or third-party configuration (1С:ERP, Бухгалтерия предприятия, Управление торговлей, ЗУП, etc.) **without modifying the original** and **without taking it off support** (без снятия с поддержки). This is the modern, update-safe way to adapt typical configurations and is usually the right answer when the user works on top of a standard solution rather than an in-house config. Explain the design in Georgian during the analysis step and justify why an extension (not a direct change) is the correct vehicle.

## Contents
- When to use an extension vs. changing the configuration directly
- How an extension attaches: borrowing vs. own objects
- Module method annotations and execution order
- Choosing the right annotation (the decision that matters most)
- &ИзменениеИКонтроль for surgical code changes
- Update resilience and what breaks on a base update
- Safe mode, privileges, and scope
- Practical checklist

## When to use an extension vs. changing the configuration directly

- **On a supported vendor configuration → always prefer an extension.** Direct edits force you to take the config off support (снять с поддержки), which makes every future vendor update a painful manual merge. An extension keeps the base intact and is re-applied on top after each update.
- **On an in-house configuration you fully own →** changing the configuration directly is fine; an extension adds indirection you may not need. Use extensions here only to isolate optional/region-specific functionality or to stage risky changes.
- **Rule of thumb:** the more "typical" (vendor-maintained) the configuration, the stronger the case for an extension.

## How an extension attaches: borrowing vs. own objects

An extension is a small, separate configuration that the platform merges with the base at runtime. Two ways to add behavior:

1. **Own objects.** Add new catalogs, documents, registers, common modules, reports, roles, subsystems, etc. that live entirely in the extension. Put as much of your custom logic here as possible — it is fully yours and is unaffected by base updates.
2. **Borrowed objects (заимствованные объекты).** Pull an existing base object into the extension to attach to it: add an attribute/form/command, or override module methods via annotations. Borrow the *minimum* surface you need.

**Core discipline:** in a borrowed module write **only** the interception code (the annotated handlers that hook the base method); put the actual business logic in your **own** common module and call into it. This keeps borrowed modules thin, makes your changes obvious against the standard, and minimizes what must be re-checked when the vendor changes that base method.

## Module method annotations and execution order

To hook a procedure/function of a borrowed module, declare a method in the extension module with one of these annotations:

- `&Перед("ИмяМетода")` (Before) — your code runs **before** the base method.
- `&После("ИмяМетода")` (After) — your code runs **after** the base method (most common for "also do X").
- `&Вместо("ИмяМетода")` (Instead) — your code **replaces** the base method entirely. You may call the original explicitly via `ПродолжитьВызов(...)`.
- `&ИзменениеИКонтроль("ИмяМетода")` (Change & Control) — surgically patch the *text* of the base method (see its own section).

```bsl
// extension module borrowing Документ.РеализацияТоваровУслуг object module
&После("ОбработкаПроведения")
Процедура Расш_ОбработкаПроведения(Отказ, РежимПроведения)
    // ქართული: ტიპური გატარების შემდეგ ვამატებთ ჩვენს მოძრაობას
    // მთელი ლოგიკა საკუთარ საერთო მოდულშია, აქ მხოლოდ გამოძახებაა
    МойМодуль.ДобавитьДвиженияПоУчетуТары(ЭтотОбъект, Отказ);
КонецПроцедуры
```

**Execution order** when several extensions hook the same method: `&Перед` handlers run first (in reverse order of the extension list), then the base method (or the `&Вместо` replacement), then `&После` handlers (also in reverse order). Do **not** design logic that depends on the relative order of two different extensions — it is fragile. Keep each hook independent and commutative where possible.

## Choosing the right annotation (the decision that matters most)

- **Prefer `&После` / `&Перед`.** They leave the base method intact, so a vendor change to that method does not silently break your addition. Reach for these first.
- **Avoid `&Вместо` unless you truly must replace behavior.** It is the riskiest: it shadows the base method and does **not** track changes to it. If the vendor later fixes a bug or changes logic in that method, your `&Вместо` keeps running the old replacement and you get no warning. If you must use it, call `ПродолжитьВызов(...)` to run the original where appropriate, and document why a full replacement was unavoidable.
- **Use `&ИзменениеИКонтроль` for targeted edits** inside an otherwise-standard method — it gives you the safety of automatic change tracking (next section).

## &ИзменениеИКонтроль for surgical code changes

When you need to change a few lines *inside* a long base method (not wrap it), `&ИзменениеИКонтроль` copies the controlled method and lets you edit it with preprocessor directives:

```bsl
&ИзменениеИКонтроль("ЗаполнитьЦеныПоУмолчанию")
Процедура Расш_ЗаполнитьЦеныПоУмолчанию(Парам)
    // ... unchanged base lines ...
    #Вставка
    // ქართული: ჩვენი დამატებითი ფასდაკლების ლოგიკა
    Парам.Цена = МойМодуль.СкорректироватьЦену(Парам.Цена, Парам.Контрагент);
    #КонецВставки
    // ... unchanged base lines ...
    #Удаление
    // ეს ბლოკი ტიპურ კოდში იყო, ჩვენ ვშლით
    #КонецУдаления
КонецПроцедуры
```

The key safety property: the platform **controls** the surrounding base text. If the vendor changes that method on the next update, the platform detects the mismatch, **does not apply** the extension, and notifies the developer to review — so you can never unknowingly run a patch against changed code. This is why `&ИзменениеИКонтроль` is the workhorse annotation for adapting typical configurations: it combines a precise edit with an automatic update guard.

## Update resilience and what breaks on a base update

- Re-test the extension after **every** base configuration update. The platform flags borrowed objects/methods whose base definition changed.
- `&Вместо` and direct property overrides are the most likely to drift silently — audit them first after an update.
- Keep a short note (in the extension or a doc) of *why* each borrowed method is hooked, so the next update review is fast.
- Name your added objects/attributes with a consistent prefix (e.g., `Расш_`, or a company prefix) so they are instantly distinguishable from base metadata.

## Safe mode, privileges, and scope

- Extensions can be attached in **safe mode** (безопасный режим), which restricts dangerous operations (external resources, privileged access). Configuration extensions developed in Designer typically run unrestricted; understand the deployment's safe-mode policy before relying on file/COM/external calls.
- An extension defines its own **roles**; access changes ship with the extension rather than being bolted onto base roles.
- Extensions cannot do *everything* — some base objects/properties are not extendable. If a requirement cannot be met by an extension, say so in the analysis step and discuss the trade-off (e.g., requesting a vendor change, or, as a last resort, a supported modification) rather than forcing a brittle `&Вместо`.

## Practical checklist

- Is this a supported vendor config? → extension, not a direct edit.
- Is custom logic in my **own** module, with borrowed modules holding only thin hooks?
- Did I prefer `&После`/`&Перед`, and justify any `&Вместо`?
- For in-method edits, did I use `&ИзменениеИКонтроль` so the platform guards against base changes?
- Are added objects clearly prefixed?
- Did I note the re-test-after-update obligation for the user, in Georgian?
