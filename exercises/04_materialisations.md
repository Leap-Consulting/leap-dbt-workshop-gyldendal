# 04 · Materialisations

By default, dbt builds every model as a `view`. Views are fast to build and always up to date, which is great for staging models, while marts that people and dashboards query directly are usually built as `table`s so they're fast to read.

You can set materialisations for whole folders in `dbt_project.yml`, or on a single model with `{{ config(materialized='...') }}`.


## Task 1: Configure folder materialisations in `dbt_project.yml`

- Add a `models:` block at the bottom of `dbt_project.yml` to build all `marts` models as tables:

```yaml
models:
  publisher_example:
    marts:
      +materialized: table
```

- Run `dbt run` and check the terminal output: `fct_orders` and `dim_customers` are now built as `[sql table model]` instead of `[sql view model]`.


## Task 2: Configure a materialisation in a model file

A `config()` block at the top of a model file sets (or overrides) the materialisation for that single model.

- At the top of `models/marts/dim_customers.sql`, add:

```sql
{{ config(materialized='view') }}
```

- Run `dbt run` and check that `dim_customers` is now again built as a `[sql view model]` (because the `config()` block takes precedence over `dbt_project.yml`).


## Task 3: Commit and push

- `git add .`
- `git commit -m "<describe your work>"`
- `git push`
