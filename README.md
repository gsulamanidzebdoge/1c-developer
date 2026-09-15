# 1C Developer — Claude Skill

**Claude-ის სქილი (Agent Skill), რომელიც Claude-ს 1C:Enterprise 8.3-ის (1С:Предприятие) სენიორ დეველოპერად და არქიტექტორად აქცევს — ქართულად საუბრით და სტანდარტების შესაბამისი BSL კოდით.**

> **English:** A Claude Agent Skill that turns Claude into a senior 1C:Enterprise 8.3 developer and architect. It explains, plans and reviews in fluent Georgian while writing standard-compliant Russian-syntax BSL code and 1C query language. Drop it into Claude Code, Claude Desktop or the API.

---

## რას აკეთებს

სქილი ორ რეჟიმში მუშაობს:

- **Build mode** — ახალი ფუნქციონალის/კოდის შექმნა სამ ნაბიჯად: **ანალიზი და არქიტექტურა → კოდი → ტესტირება და სასაზღვრო შემთხვევები**. მეტამონაცემების დიზაინი (справочник / документ / регистр) კოდის დაწერამდე განიხილება და ასაბუთდება.
- **Review mode** — არსებული კოდის აუდიტი `references/code-review-checklist.md`-ის მიხედვით: კორექტულობა → კონკურენტულობა → წარმადობა → სტანდარტები → უსაფრთხოება → ლოკალიზაცია. შედეგი სიმძიმის დონეებად დაჯგუფებული: 🔴 კრიტიკული / 🟠 მნიშვნელოვანი / 🟡 მცირე / 🟢 რეკომენდაცია.

### ენობრივი წესი

- **მთელი პროზა — ქართულად:** გეგმები, ახსნები, trade-off-ების განხილვა, ტესტირების ინსტრუქციები.
- **კოდი — სტანდარტული BSL:** ნაგულისხმევად რუსული სინტაქსით (`Процедура`, `&НаСервере`, `ВЫБРАТЬ`), თუ მომხმარებლის კოდი ინგლისურ სინტაქსზეა — შესაბამისად იცვლება.
- **UI სტრიქონები** ყოველთვის `НСтр()`-ში, ქართული თარგმანით: `НСтр("ru = 'Документ проведён'; ka = 'დოკუმენტი გატარდა'")`.

## რას ფარავს

| ფაილი | თემა |
| --- | --- |
| [`references/development-standards.md`](references/development-standards.md) | მოდულის სტრუქტურა, რეგიონები, ნეიმინგი, კომპილაციის დირექტივები, ასინქრონული კლიენტური მოდელი (`Асинх`/`Ждать`), შეცდომების დამუშავება, ლოგირება, `НСтр`, БСП |
| [`references/query-language-and-optimization.md`](references/query-language-and-optimization.md) | მოთხოვნის ენა, ვირტუალური ცხრილები, დროებითი ცხრილები, ოპტიმიზაციის ჩეკლისტი და ანტი-პატერნები |
| [`references/locking-transactions-posting.md`](references/locking-transactions-posting.md) | მართვადი ბლოკირებები, deadlock-ის თავიდან აცილება, ტრანზაქციები, `ОбработкаПроведения` |
| [`references/metadata-modeling.md`](references/metadata-modeling.md) | არჩევანი catalog / document / register ტიპებს შორის, მოდელირების პატერნები |
| [`references/configuration-extensions.md`](references/configuration-extensions.md) | расширения конфигурации, `&Перед/&После/&Вместо/&ИзменениеИКонтроль`, ტიპური კონფიგურაციის მხარდაჭერიდან მოუხსნელი ადაპტაცია |
| [`references/integration-and-exchange.md`](references/integration-and-exchange.md) | HTTP/web სერვისები, REST, JSON/XML/XDTO, EnterpriseData, გაცვლის გეგმები, იდემპოტენტურობა |
| [`references/platform-mechanisms.md`](references/platform-mechanisms.md) | ფონური და რეგლამენტური დავალებები, `ДлительныеОперации`, ფუნქციონალური ოფციები, დინამიკური სიები, უფლებები და RLS |
| [`references/code-review-checklist.md`](references/code-review-checklist.md) | Review-რეჟიმის სრული ჩეკლისტი და ქართული ანგარიშის შაბლონი |
| [`references/worked-example-managed-form.md`](references/worked-example-managed-form.md) | სრული end-to-end მაგალითი: ობიექტის მოდული + მართვადი ფორმა + საერთო მოდული |
| [`references/georgian-glossary.md`](references/georgian-glossary.md) | ქართული ტერმინოლოგია რუსული/ინგლისური კანონიკური ტერმინების გვერდით |

## ინსტალაცია

### Claude Code

```bash
git clone https://github.com/gsulamanidzebdoge/1c-developer.git ~/.claude/skills/1c-developer
```

ან პროექტის დონეზე — `.claude/skills/1c-developer/`. სქილი ავტომატურად ჩაირთვება, როცა საუბარი 1C-ს, BSL-ს, БСП-ს ან 1С:ERP/УТ/БП/ЗУП-ს შეეხება.

### Claude Desktop / API

ატვირთეთ `1c-developer.skill` ბანდლი (იგივე შიგთავსი, შეფუთული) Skills-ის ინტერფეისიდან.

## გამოყენების მაგალითი

```
დამჭირდა დოკუმენტი „მასალის ჩამოწერა", რომელიც მარაგების რეგისტრს ამოძრავებს
და გატარებისას ნაშთის უარყოფითობას ამოწმებს.
```

Claude დაიწყებს მეტამონაცემების დიზაინის განხილვით (ქართულად), შემდეგ დაწერს `ОбработкаПроведения`-ს მართული ბლოკირებებით და დაასრულებს ტესტირების სცენარებით — კონკურენტული გატარება, უარყოფითი ნაშთი, თარიღის საზღვრები.

## რეპოზიტორიის სტრუქტურა

```
SKILL.md                     # სქილის ძირითადი ინსტრუქცია + frontmatter
references/                  # თემატური საცნობარო ფაილები (საჭიროებისამებრ იტვირთება)
1c-developer.skill           # შეფუთული ბანდლი განაწილებისთვის
```

## ლიცენზია

[MIT](LICENSE)
