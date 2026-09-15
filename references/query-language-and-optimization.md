# 1C Query Language & Optimization (Язык запросов 1С)

Reference for writing correct, fast 1C queries. Code uses Russian-syntax query language by default.

## Contents
- Query basics and clause order
- Virtual tables (the key to register performance)
- Temp tables and batch queries (пакетные запросы)
- The optimization checklist
- Anti-patterns to avoid (especially "query in a loop")
- Row-level security: РАЗРЕШЕННЫЕ
- Reading query results efficiently

## Query basics and clause order

```sql
ВЫБРАТЬ
    Товары.Номенклатура КАК Номенклатура,
    СУММА(Товары.Количество) КАК Количество
ИЗ
    Документ.РеализацияТоваров.Товары КАК Товары
ГДЕ
    Товары.Ссылка.Дата МЕЖДУ &НачалоПериода И &КонецПериода
СГРУППИРОВАТЬ ПО
    Товары.Номенклатура
ИМЕЮЩИЕ
    СУММА(Товары.Количество) > 0
УПОРЯДОЧИТЬ ПО
    Количество УБЫВ
ИТОГИ
    СУММА(Количество) ПО ОБЩИЕ
```

Useful constructs: `ВЫБОР КОГДА ... ТОГДА ... ИНАЧЕ ... КОНЕЦ` (CASE), joins `ЛЕВОЕ/ВНУТРЕННЕЕ/ПОЛНОЕ СОЕДИНЕНИЕ`, `ОБЪЕДИНИТЬ ВСЕ` (UNION ALL — prefer over `ОБЪЕДИНИТЬ` unless you truly need de-duplication), `ПЕРВЫЕ N` (TOP), `РАЗЛИЧНЫЕ` (DISTINCT), `ЕСТЬNULL`/`ЕСТЬ NULL`, parameters with `&`.

## Virtual tables — the key to register performance

Do **not** recompute balances or turnovers by summing over documents. Registers expose virtual tables that the platform computes efficiently from stored totals:

- Accumulation register (регистр накопления):
  - `РегистрНакопления.ТоварыНаСкладах.Остатки(&НаДату, Склад = &Склад)` — balances.
  - `РегистрНакопления.ТоварыНаСкладах.Обороты(&Начало, &Конец, , ...)` — turnovers.
  - `...ОстаткиИОбороты(...)` — both at once.
- Information register (регистр сведений, periodic):
  - `РегистрСведений.ЦеныНоменклатуры.СрезПоследних(&НаДату, Номенклатура = &Номенклатура)` — latest values as of a date.
  - `...СрезПервых(...)` — earliest.

**Always pass filters as virtual-table parameters**, not in the outer `ГДЕ`. This lets the platform restrict data before materializing the result — dramatically faster on large registers.

```sql
// ✅ filter inside the virtual table
ВЫБРАТЬ Остатки.Номенклатура, Остатки.КоличествоОстаток
ИЗ РегистрНакопления.ТоварыНаСкладах.Остатки(&НаДату, Склад = &Склад) КАК Остатки

// ❌ filtering after the fact forces a wider computation
ВЫБРАТЬ Остатки.Номенклатура, Остатки.КоличествоОстаток
ИЗ РегистрНакопления.ТоварыНаСкладах.Остатки(&НаДату, ) КАК Остатки
ГДЕ Остатки.Склад = &Склад
```

## Temp tables and batch queries (пакетные запросы)

For complex logic, stage intermediate sets into temp tables with `ПОМЕСТИТЬ` and join against them, instead of nesting subqueries. Use a `МенеджерВременныхТаблиц` to share temp tables across a batch.

```sql
ВЫБРАТЬ Номенклатура.Ссылка КАК Номенклатура
ПОМЕСТИТЬ ВыбраннаяНоменклатура
ИЗ Справочник.Номенклатура КАК Номенклатура
ГДЕ Номенклатура.ГруппаТоваров = &Группа
;
ВЫБРАТЬ Остатки.Номенклатура, Остатки.КоличествоОстаток
ИЗ РегистрНакопления.ТоварыНаСкладах.Остатки(&НаДату, 
        Номенклатура В (ВЫБРАТЬ Номенклатура ИЗ ВыбраннаяНоменклатура)) КАК Остатки
```

Indexing a temp table you will join on (`ИНДЕКСИРОВАТЬ ПО`) helps when it is large.

## The optimization checklist

1. **No query inside a loop.** Build one set-based query (see anti-patterns below). This is the number-one performance killer in 1C.
2. **Use virtual tables** for balances/turnovers/slices instead of aggregating raw documents.
3. **Filter inside virtual-table parameters**, not in the outer `ГДЕ`.
4. **Select only needed columns.** Don't `ВЫБРАТЬ *`-style pull everything; wide rows cost memory and network.
5. **Index-friendly conditions.** Don't wrap an indexed field in a function in the `ГДЕ` (e.g., avoid comparing on a computed expression of an indexed field). Filter on the field directly.
6. **Avoid `ПОДОБНО '%text%'`** with a leading wildcard — it cannot use an index. Anchor patterns where possible.
7. **Prefer `ОБЪЕДИНИТЬ ВСЕ`** over `ОБЪЕДИНИТЬ` unless de-duplication is required.
8. **Join on indexed/typed fields**; beware joins on fields of composite (составной) type, which are slow — narrow the type first.
9. **Watch `.Ссылка.Реквизит` dotted access** through references in filters; for hot paths, join the referenced table explicitly so the optimizer can use indexes.
10. **Use temp tables** to break up heavy nested subqueries and to constrain virtual tables by a pre-filtered set.

## Anti-patterns to avoid

**Query in a loop (запрос в цикле) — never do this:**

```bsl
// ❌ executes one query per row — catastrophic on volume
Для Каждого Стр Из Товары Цикл
    Запрос = Новый Запрос("ВЫБРАТЬ Цена ИЗ РегистрСведений.Цены.СрезПоследних(&Д, Номенклатура=&Н)");
    Запрос.УстановитьПараметр("Н", Стр.Номенклатура);
    // ...
КонецЦикла;
```

```bsl
// ✅ one query for all rows, then iterate the result
Запрос = Новый Запрос;
Запрос.Текст =
    "ВЫБРАТЬ Цены.Номенклатура, Цены.Цена
    |ИЗ РегистрСведений.Цены.СрезПоследних(&Дата, 
    |        Номенклатура В (&СписокНоменклатуры)) КАК Цены";
Запрос.УстановитьПараметр("Дата", Дата);
Запрос.УстановитьПараметр("СписокНоменклатуры", Товары.ВыгрузитьКолонку("Номенклатура"));
Выборка = Запрос.Выполнить().Выбрать();
Пока Выборка.Следующий() Цикл
    // ...
КонецЦикла;
```

Other anti-patterns: building query text by string-concatenating user input (use parameters); selecting into a `ТаблицаЗначений` only to loop and run more queries; calling `.Выполнить()` repeatedly when one batch would do.

## Row-level security: РАЗРЕШЕННЫЕ

When access restrictions (RLS) are configured and you want the query to silently skip forbidden records instead of raising an error, use `ВЫБРАТЬ РАЗРЕШЕННЫЕ`. Omit it (or run in a privileged context) only when you deliberately need the full set and understand the security implication.

## Reading query results efficiently

- For row-by-row processing use `.Выбрать()` and `Пока Выборка.Следующий() Цикл`.
- For grouped/hierarchical reads use `.Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам)`.
- To hand the whole set to other code use `.Выгрузить()` into a `ТаблицаЗначений`.
- Check `.Пустой()` before processing when an empty result needs a distinct path.
- Set parameters with `УстановитьПараметр` — never interpolate values into the query text.
