# 01 · Sources

Sources tell dbt where the raw data lives, so your models can use `{{ source('shop', 'orders') }}` instead of hard-coded database and table names. In this exercise you explore the existing `shop` source, and add a source for the payments.

## Task 1: Look at the existing sources

- Open `models/staging/shop/_shop__sources.yml` and look at the sources defined there.

- Create a temporary file (`test.sql` or similar) anywhere under the `models/` folder.
  - Write: `select * from {{ source('shop', 'imprints') }}`

- Click the preview button to see a few rows
- Click the compile button to see the compiled SQL, where `source()` has been replaced by the full table name

## Task 2: Add a new source

- Create a file `models/staging/payments/_payments__sources.yml`
- Add a source for the payments, which are in the raw table `payments.trx_export_v2`. Call the source `payments`, and add the table `trx_export_v2` to it. You can use `_shop__sources.yml` as a template
- Change `test.sql` to `select * from {{ source('payments', 'trx_export_v2') }}`, and verify that it now compiles and/or can be previewed


## Task 3: Commit and push

- `git add .`
- `git commit -m "<describe your work>"`
- `git push -u origin feat/workshop-<your initials>` (`-u origin …` is only needed the first time you push a new branch)


