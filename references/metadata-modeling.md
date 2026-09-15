# Metadata Modeling Patterns

How to map a business requirement onto the right 1C metadata objects. This is the highest-leverage decision in 1C development: the data structure constrains everything you can do later and is costly to change once data accumulates. Do this in the analysis step (ნაბიჯი 1) and justify it in Georgian to the user.

## Contents
- The core metadata objects and when to use each
- Decision guide: which object for which need
- Register types in depth
- Common modeling patterns
- Worked example

## The core metadata objects

| Object (RU / EN) | Models | Key trait |
|---|---|---|
| Справочник / Catalog | Master data: items, partners, warehouses, employees | Relatively static lists; can be hierarchical; has predefined items |
| Документ / Document | Business events at a point in time: sale, receipt, payment | Has date+number, can be posted (проведён), drives registers |
| Регистр сведений / Information register | State/attributes over time or by key: prices, exchange rates, settings | Stores values by dimensions; can be periodic (slices) |
| Регистр накопления / Accumulation register | Quantities that accumulate: stock, money balances, turnovers | Balances + turnovers virtual tables |
| Регистр бухгалтерии / Accounting register | Double-entry accounting with chart of accounts | Dr/Cr, account correspondence |
| Регистр расчёта / Calculation register | Payroll/period calculations with recalculation | Time-based calc, recalcs |
| Перечисление / Enumeration | Fixed sets of options: statuses, types | Compile-time constants, no user editing |
| Константа / Constant | Single global settings value | One value per configuration |
| План видов характеристик / CharacteristicKinds | User-extensible attributes | Dynamic properties |
| План счетов / Chart of accounts | Accounts for accounting register | Pairs with accounting register |
| Обработка / DataProcessor, Отчёт / Report | Tools and read-only outputs | No own persistent table (reports) |

## Decision guide: which object for which need

- **"A list of things people pick from"** → Справочник (Catalog). Hierarchical if it has groups. Use предопределённые элементы for items the code must reference by name.
- **"Something happened on a date that should be recorded"** → Документ (Document). If it changes balances or money, it should post movements into registers.
- **"A value that depends on a key and possibly on time"** (price by item, rate by date, a setting by organization) → Регистр сведений (Information register). Make it **periodic** if you need "the value as of date X" (use СрезПоследних).
- **"How much of something do we have / how much moved"** (stock on hand, cash balance, debt) → Регистр накопления (Accumulation register). Choose subtype:
  - **Остатки (balance)** — you care about the current quantity (stock on warehouse, account balance).
  - **Обороты (turnover)** — you only care about flows over a period (sales volume, traffic), never a running balance.
- **"Debits and credits across accounts"** → Регистр бухгалтерии + План счетов.
- **"A fixed option set the user shouldn't edit"** → Перечисление, not a catalog. Compare with `Перечисления...`.
- **"A single configurable setting"** → Константа (or a settings object/информационный регистр if there are many related settings).

A frequent mistake is storing status/type as a string in a catalog or document attribute. Use an enumeration so logic is explicit, fast, and translatable.

## Register types in depth

**Accumulation register, balance kind (остатки):** has dimensions (Измерения — e.g., Склад, Номенклатура), resources (Ресурсы — e.g., Количество, Сумма), and optional attributes (Реквизиты). Records have a direction (Приход/Расход). Query via `.Остатки`, `.Обороты`, `.ОстаткиИОбороты`. Use for anything you must answer "how much is left" about.

**Accumulation register, turnover kind (обороты):** only sums flows; no balance is maintained, so it is cheaper when you never need a running total. Query via `.Обороты`.

**Information register (регистр сведений):**
- Dimensions identify the row; resources hold the values.
- **Periodic** registers add a Period and let you ask for slices: `СрезПоследних(&Дата, ...)` (latest as of date) and `СрезПервых`. Ideal for prices and rates.
- Write mode: **independent** (write any record directly) vs **subordinate to recorder** (records owned by a document, written/cleared with its posting). Choose subordinate when a document is the source of truth.

## Common modeling patterns

- **Stock management:** Документ "Поступление"/"Реализация" posts into Регистр накопления "ТоварыНаСкладах" (balance kind, dimensions Склад+Номенклатура, resource Количество). Current stock = `.Остатки`. Balance control happens in posting with a managed lock.
- **Pricing:** Периодический Регистр сведений "ЦеныНоменклатуры" (dimensions Номенклатура [+ ТипЦен], resource Цена). Current price = `СрезПоследних`.
- **Mutual settlements / debt:** Регистр накопления (balance) by Контрагент/Договор, resource Сумма, with Приход/Расход from invoices and payments.
- **Statuses / lifecycle:** Перечисление for the states; transitions enforced in object-module logic, never as free-text.
- **Extensible attributes:** План видов характеристик + a Регистр сведений to store characteristic values, when users must add their own properties.

## Worked example

Requirement (paraphrased): "Track customer orders, reserve stock when an order is confirmed, and report stock available to promise."

Mapping:
- **Документ "ЗаказПокупателя"** — the order event (date, number, customer, lines).
- **Перечисление "СтатусыЗаказов"** — Черновик / Подтверждён / Выполнен / Отменён (no free-text status).
- **Справочник "Номенклатура", "Склады", "Контрагенты"** — master data.
- **Регистр накопления "ТоварыНаСкладах"** (balance) — physical stock.
- **Регистр накопления "ТоварыКОтгрузке" / резерв** (balance) — reserved quantity, posted by the order when status = Подтверждён.
- Available-to-promise = `ТоварыНаСкладах.Остатки` − `Резерв.Остатки`, computed in one query joining both virtual tables.
- Concurrency: lock the reserve register dimensions during confirmation posting to prevent two orders over-reserving the same stock.

Presenting this design in Georgian, with the justification for each object, is exactly the output of analysis step 1.
