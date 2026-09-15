# Locking, Transactions & Document Posting

Reference for concurrency-correct 1C code: managed data locks (управляемые блокировки), deadlock avoidance, transactions, and document posting (проведение). This is where multi-user bugs and data corruption hide, so treat it carefully.

## Contents
- Managed vs automatic lock mode
- Managed locks: how and when
- Deadlock avoidance
- Transaction discipline
- Document posting (ОбработкаПроведения)
- Object (form) locking: optimistic vs pessimistic

## Managed vs automatic lock mode

Modern configurations use the **managed lock mode** (`Управляемый`) at the configuration/object level. In this mode the developer is responsible for setting locks explicitly where business logic requires consistency (e.g., reading a balance and then writing based on it). The platform no longer escalates locks automatically the way the old automatic mode did, which means better concurrency — but only if you lock deliberately.

## Managed locks: how and when

Set a lock when you read data that you will then modify, so another session cannot change it underneath you between read and write. The classic case: posting a document that must not drive a stock balance negative.

```bsl
Блокировка = Новый БлокировкаДанных;
Элемент = Блокировка.Добавить("РегистрНакопления.ТоварыНаСкладах.Остатки");
Элемент.Режим = РежимБлокировкиДанных.Исключительный; // или Разделяемый для чтения
Элемент.УстановитьЗначение("Склад", Склад);
// можно ограничить набор по источнику данных (по таблице документа)
Блокировка.Заблокировать(); // внутри транзакции!

// ... теперь читаем остатки и формируем движения, зная, что данные стабильны ...
```

Key points:
- A managed lock is only meaningful **inside a transaction**; it is released when the transaction ends.
- Use `Разделяемый` (shared) when you only read and want to block writers; `Исключительный` (exclusive) when you will write.
- Constrain the lock to the **specific dimensions/values** you touch (`УстановитьЗначение`) so you don't lock the whole register and serialize unrelated work.
- Lock **before** you read the data you intend to act on — the read-then-lock order leaves a race window.

## Deadlock avoidance

Deadlocks happen when two transactions lock the same resources in opposite orders. Defenses:

1. **Consistent lock ordering.** Always acquire locks on multiple resources in the same global order across all code paths (e.g., always register A before register B). This single rule prevents most deadlocks.
2. **Lock the minimum scope.** Narrow locks (specific dimension values) collide far less than table-wide locks.
3. **Keep transactions short.** Do all slow work (queries, preparation) before opening the transaction; inside it, do only the read-lock-write that must be atomic. Never wait on user input or external calls inside a transaction.
4. **Lock early, at the right granularity.** Acquiring the needed exclusive lock up front avoids the lock-upgrade pattern (shared→exclusive) that commonly deadlocks.

## Transaction discipline

```bsl
НачатьТранзакцию();
Попытка
    // managed locks here
    // reads + writes that must be atomic
    ЗафиксироватьТранзакцию();
Исключение
    ОтменитьТранзакцию();
    ЗаписьЖурналаРегистрации(НСтр("ru='Транзакция'; ka='ტრანზაქცია'"),
        УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
    ВызватьИсключение;
КонецПопытки;
```

Rules: every `НачатьТранзакцию` is paired with exactly one commit or rollback on every path; always roll back in the exception handler; don't nest business transactions casually (1C uses a transaction counter — inner "transactions" just increment it, so a single failure rolls back the whole outer scope). Don't perform interactive or long external operations inside a transaction.

## Document posting (ОбработкаПроведения)

Posting runs in the object module and writes register movements. The platform already wraps posting in a transaction and locks the records being written; your job is to compute correct movements and, where business rules require, lock and check balances.

```bsl
Процедура ОбработкаПроведения(Отказ, РежимПроведения)
    // ქართული: მოძრაობების ფორმირება და ნაშთის შემოწმება

    Движения.ТоварыНаСкладах.Записывать = Истина;

    // For balance control, set the register to read the locked balance:
    Движения.ТоварыНаСкладах.БлокироватьДляИзменения = Истина;
    Движения.Записать(); // записать движения, чтобы учесть их в остатках

    // Затем проверить остатки запросом по таблице остатков и,
    // при нехватке, установить Отказ = Истина и сообщить пользователю через НСтр.
КонецПроцедуры
```

Guidance: choose **proactive** (control on posting) vs **retrospective** (allow then report) balance control consciously — proactive control needs locking to be correct under concurrency. Form movements set-based, not row-by-row with per-row queries. Clear/rewrite movements idempotently so re-posting is safe. Respect `РежимПроведения` (Оперативный/Неоперативный) — real-time posting checks current balances; non-real-time (e.g., back-dated) typically does not.

## Object (form) locking: optimistic vs pessimistic

Separate from data locks, the platform protects interactive editing of an object:
- **Optimistic locking** detects that the object's version changed since you loaded it and prevents overwriting someone else's save (version mismatch error). It is automatic.
- **Pessimistic locking** locks the object for editing when a user opens it for change, so others get a read-only/"object is locked" state.

When writing custom save logic, surface these conditions to the user with a clear localized message rather than a raw platform error.
