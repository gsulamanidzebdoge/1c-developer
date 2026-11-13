# 1C Developer — Claude Skill

**Claude-ის სქილი (Agent Skill), რომელიც Claude-ს 1C:Enterprise 8.3-ის (1С:Предприятие) სენიორ დეველოპერად და არქიტექტორად აქცევს — ქართულად საუბრით და სტანდარტების შესაბამისი BSL კოდით.**

> **English:** A Claude Agent Skill that turns Claude into a senior 1C:Enterprise 8.3 developer and architect. It explains, plans and reviews in fluent Georgian while writing standard-compliant Russian-syntax BSL code and 1C query language. Drop it into Claude Code, Claude Desktop or the API.

---

## რას აკეთებს

სქილი სამ რეჟიმში მუშაობს:

- **Build mode** — ახალი ფუნქციონალის/კოდის შექმნა სამ ნაბიჯად: **ანალიზი და არქიტექტურა → კოდი → ტესტირება და სასაზღვრო შემთხვევები**. მეტამონაცემების დიზაინი (справочник / документ / регистр) კოდის დაწერამდე განიხილება და ასაბუთდება.
- **Review mode** — არსებული კოდის აუდიტი `references/code-review-checklist.md`-ის მიხედვით: კორექტულობა → კონკურენტულობა → წარმადობა → სტანდარტები → უსაფრთხოება → ლოკალიზაცია. შედეგი სიმძიმის დონეებად დაჯგუფებული: 🔴 კრიტიკული / 🟠 მნიშვნელოვანი / 🟡 მცირე / 🟢 რეკომენდაცია.
- **Conversion mode** — ბინარული 1C ფაილის (`.erf`, `.epf`, `.cf`, `.cfe`) XML-ად დაშლა და უკან აწყობა Git-ისთვის, diff-ისთვის, code review-სა და CI/CD-ისთვის: Designer-ის პაკეტური რეჟიმი, `ibcmd`, EDT `ring`, OneScript. შედეგი — მზა, გასაშვები სკრიპტი ლოგირებით, exit-code-ის შემოწმებით და round-trip გადამოწმების ინსტრუქციით.

### ინსტრუმენტარიუმი: cc-1c-skills

სქილი იცნობს [cc-1c-skills](https://github.com/Nikolay-Shirokov/cc-1c-skills) პლაგინს (Nikolay Shirokov, MIT — დაახლოებით 80 სქილი 1C-ის XML-ფორმატებისა და კონფიგურატორის CLI-ზე) და, როცა ის დაინსტალირებულია, **რეალურ არტეფაქტებს მისი სქილებით აგებს** — არ წერს XML-ს ხელით და არ აწყობს `1cv8.exe`-ის ბრძანებებს თვითონ.

შრომის განაწილება ასეთია: **cc-1c-skills** აგებს არტეფაქტის მექანიკას (UUID-ები, namespace-ები, `Configuration.xml`-ში რეგისტრაცია, პლატფორმის გაშვება), **`1c-developer`** — მეტამონაცემების დიზაინს, მოდულებში ჩაწერილ BSL-ს, ქართულ ახსნას და ტესტირების გეგმას. პლაგინის გარეშე სქილი არსებულ რეჟიმში აგრძელებს — აძლევს მზა, გასაშვებ სკრიპტს.

```
/plugin marketplace add https://github.com/Nikolay-Shirokov/cc-1c-skills
/plugin install 1c-skills@cc-1c-skills        # PowerShell (Windows)
/plugin install 1c-skills-py@cc-1c-skills     # Python
```

### დამრთევი სქილი: product-analyst

სქილი წერს კოდს — არა მოთხოვნებს. თუ დავალება ТЗ-ია, ЧТЗ-ია, постановка задачи-ა, обследование, FIT/GAP, ბექლოგი ან პრიორიტიზაცია — ეს [`product-analyst`](https://github.com/gsulamanidzebdoge/product-analyst)-ის სამუშაოა.

| | `product-analyst` | `1c-developer` |
| --- | --- | --- |
| წყვეტს | **რა** უნდა აშენდეს და გირს თუ არა | **როგორ** აშენდება |
| აწარმოებს | გადაწყვეტილებას, მოთხოვნებს, სპეციფიკაციას, მიღების კრიტერიუმებს | BSL კოდს, მეტამონაცემებს, ფორმებს, СКД-ს, გაფართოებებს |
| ხედება | постановка-ზე | კოდის შემდეგ, ტესტირების გეგმაზე |

გადაცემა სუფთაა, როცა დეველოპერს კითხვა აღარ უჩნდება: ზუსტი მეტამონაცემების გზა, ზუსტი ტიპები, მოძრაობები ნიშნებით, შეტყობინებების ტექსტები, უფლებების მატრიცა და საკონტროლო მაგალითი.

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
| [`references/cc-1c-skills-integration.md`](references/cc-1c-skills-integration.md) | cc-1c-skills პლაგინი: აღმოჩენა, სქილების კატალოგი, `.v8-project.json` რეესტრი, ტიპური ჯაჭვები, ხაფანგები და fallback |
| [`references/source-conversion.md`](references/source-conversion.md) | `.erf`/`.epf`/`.cf`/`.cfe` ↔ XML: Designer-ის პაკეტური რეჟიმის გასაღებები, `ibcmd`, EDT `ring`, `precommit1c`/`vrunner`, Git-ის კონფიგურაცია, ხაფანგები და round-trip ტესტი |
| [`references/worked-example-managed-form.md`](references/worked-example-managed-form.md) | სრული end-to-end მაგალითი: ობიექტის მოდული + მართვადი ფორმა + საერთო მოდული |
| [`references/georgian-glossary.md`](references/georgian-glossary.md) | ქართული ტერმინოლოგია რუსული/ინგლისური კანონიკური ტერმინების გვერდით |

## ინსტალაცია

### Claude Code — პლაგინად (რეკომენდებული)

```
/plugin marketplace add gsulamanidzebdoge/1c-developer
/plugin install 1c-developer@gsulamanidze-skills
/plugin install product-analyst@gsulamanidze-skills   # არჩევითი: ТЗ, ЧТЗ, FIT/GAP, ბექლოგი
```

ერთი marketplace — `gsulamanidze-skills` — ორივე პლაგინს შეიცავს. `product-analyst`-ის რეპოზიტორიიდან დამატებული marketplace იგივე სახელითა და იგივე სიით მოდის, ამიტომ საკმარისია ერთ-ერთის დამატება.

### Claude Code — სქილად

```bash
git clone https://github.com/gsulamanidzebdoge/1c-developer.git ~/.claude/skills/1c-developer
```

ან პროექტის დონეზე — `.claude/skills/1c-developer/`. სქილი ავტომატურად ჩაირთვება, როცა საუბარი 1C-ს, BSL-ს, БСП-ს ან 1С:ERP/УТ/БП/ЗУП-ს შეეხება.

### Claude Desktop / API

ატვირთეთ `1c-developer.skill` ბანდლი (იგივე შიგთავსი, შეფუთული) Skills-ის ინტერფეისიდან.

ბანდლი სამუშაო ხიდან ეწყობა: `python tools/build-skill-bundle.py`. სკრიპტი ამოწმებს, რომ `plugin.json`-ისა და `marketplace.json`-ის ვერსია ერთმანეთს ემთხვევა და `description` 1024 სიმბოლოს არ აღემატება, ხოლო `.bat`-ებს CRLF-ით ფუთავს.

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
scripts/                     # გასაშვები სკრიპტების შაბლონები კონვერტაციისთვის (.bat / .sh)
tools/build-skill-bundle.py  # ბანდლის აწყობა და რელიზის შემოწმებები
1c-developer.skill           # შეფუთული ბანდლი განაწილებისთვის
```

## ლიცენზია

[MIT](LICENSE)
