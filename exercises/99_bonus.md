# Bonus Exercises

For when you're done with the main exercises. They don't depend on each other, so pick the ones that interest you. The tag after a title says which exercise you need to have done first.


## Source freshness [after 01_sources]

Source freshness checks when your sources were last loaded, so you find out that a load has failed before the people who use the data do.

- In `_shop__sources.yml`, add the `config` block below:

```yaml
sources:
  - name: shop
    database: raw
    schema: shop
    config:
      loaded_at_field: _loaded_at
      freshness:
        warn_after: {count: 12, period: hour}
        error_after: {count: 24, period: hour}
    tables:
      …
```

- Run `dbt source freshness` to see everything fail
- Change the period to `day` (the longest period dbt supports) and/or the counts to higher numbers, to see the sources warn or pass.

If you're past the daily load, the sources are fresh, so they pass right away. Lower the counts, or change the period to `minute`, to see them warn or fail.


## Regression test dim_customers against the old script [after 02_models]

Before you replace an old report, check that the new model gives the same result. The query below returns the rows in `dim_customers` that the old customer overview script doesn't produce.

Preview it (for example in a temporary model file, like `test.sql` from exercise 01), and then swap the two halves to see the other direction. Can you explain the differences?

```sql
select * from {{ ref('dim_customers') }}

minus

select
    c.cust_no as customer_id,
    c.first_name,
    c.last_name,
    lower(trim(c.email)) as email,
    c.zip_code,
    o.first_order_date,
    o.most_recent_order_date,
    coalesce(o.number_of_orders, 0) as number_of_orders,
    coalesce(o.lifetime_value_dkk, 0) as lifetime_value_dkk
from raw.shop.customers c
left join (
    select
        ord.cust_no,
        min(cast(ord.order_ts as date)) as first_order_date,
        max(cast(ord.order_ts as date)) as most_recent_order_date,
        count(*) as number_of_orders,
        sum(coalesce(pay.amount_ore, 0)) / 100 as lifetime_value_dkk
    from raw.shop.orders ord
    left join (
        select order_no, sum(amount_ore) as amount_ore
        from raw.payments.trx_export_v2
        where status = 'OK'
        group by order_no
    ) pay
        on ord.order_no = pay.order_no
    where ord.status_cd <> 'X'
    group by ord.cust_no
) o
    on c.cust_no = o.cust_no
```

<details>
<summary>Solution (click to expand)</summary>

- For a number of customers, the first or most recent order date differs by one day. The old script uses UTC dates, so orders placed just after midnight Danish time get the previous day's date. Your model uses Danish time.
- If you've done exercise 03, customer 1042 appears twice in the old script's result (an old and a new row), but only once in yours.

</details>


## Add a `relationships` test [after 03_tests]

A `relationships` test checks that every value in a column exists in another model, like a foreign key. It finds orphans, such as orders that point to a customer who doesn't exist.

Add a `relationships` test that checks that every `customer_id` in `stg_shop__orders` exists in `stg_shop__customers`. Run the test. It fails.

Should you fix it in the source, filter the orders out, or accept it? Discuss it with the person next to you. Then turn the test into a warning with `severity: warn`, and write a comment explaining why.

<details>
<summary>Solution (click to expand)</summary>

```yaml
      - name: customer_id
        data_tests:
          - relationships:
              arguments:
                to: ref('stg_shop__customers')
                field: customer_id
              config:
                severity: warn  # Known issue: a few orders reference customers missing from the shop export. Reported to the e-commerce team.
```

Three orders point to customer 9999, who doesn't exist. It's a problem in the source system, so the right solution is to get it fixed there. Until then, a warning is better than an error. The orders are real and should count in the revenue, so they shouldn't be filtered out.

</details>

## Add a unit test [after 03_tests]

Data tests check the data, while unit tests check your logic: they run a model's SQL on a few rows you define yourself, and compare the result with the rows you expect.

`models/staging/shop/_shop__unit_tests.yml`:

```yaml
unit_tests:
  - name: test_stg_shop__orders_decodes_status
    description: Every shop status code is translated to a readable status.
    model: stg_shop__orders
    given:
      - input: source('shop', 'orders')
        rows:
          - {order_no: 1, status_cd: P}
          - {order_no: 2, status_cd: S}
          - {order_no: 3, status_cd: D}
          - {order_no: 4, status_cd: X}
    expect:
      rows:
        - {order_id: 1, status: placed}
        - {order_id: 2, status: shipped}
        - {order_id: 3, status: delivered}
        - {order_id: 4, status: cancelled}
```

Run it with `dbt test --select test_stg_shop__orders_decodes_status`. You only need to specify the columns that matter for the test. The rest become `null`.


## Write a doc block [after 05_documentation]

Doc blocks are descriptions written in Markdown files, which you use in the YAML files with `doc()`. They're useful when a description is long, for example a table, or when the same description is needed in several places.

- Create a new file `models/docs/order_status.md` with the following content:
```
{% docs order_status %}
The status of the order, decoded from the shop status code (`STATUS_CD`).

| status    | code | meaning                                             |
|-----------|------|-----------------------------------------------------|
| placed    | P    | The order has been received but not shipped yet     |
| shipped   | S    | The order has left the warehouse                    |
| delivered | D    | The customer has received the order                 |
| cancelled | X    | The order was cancelled                             |

Only the most recent orders can still be `placed` or `shipped`.
{% enddocs %}
```

- In `_marts__models.yml`, reference this on the `status` column like so:
```yaml
      - name: status
        description: '{{ doc("order_status") }}'
```

- Run `dbt docs generate` and `dbt docs serve` to view the resulting doc block in the documentation.



# Extra exercises that can be done in any order [after 02_models]


## Add a macro

Amounts and prices in the raw data are in øre, so the same `/ 100` shows up in several models. A macro lets you write that logic once, and reuse it everywhere.

`macros/ore_to_dkk.sql`:

```sql
{% macro ore_to_dkk(column_name, scale=2) %}
    round({{ column_name }} / 100, {{ scale }})
{% endmacro %}
```

Use it instead of `/ 100` in `stg_shop__titles.sql` and `stg_payments__transactions.sql`:

```sql
        {{ ore_to_dkk('price_ore') }} as price_dkk,
```

```sql
        {{ ore_to_dkk('amount_ore') }} as amount_dkk,
```


## `dbt ls` and selection criteria

You rarely want to build the whole project at once. Selectors let you pick exactly the models you need, and `dbt ls` shows what a selection picks without running anything.

Write down which models you think each selection chooses. Then check with `dbt ls`, for example:

```
dbt ls --resource-type model -s +fct_orders
```

| Selection | Your guess |
|---|---|
| `-s +fct_orders` | |
| `-s stg_shop__orders+` | |
| `-s staging` | |
| `-s source:payments+` | |
| `-s +dim_customers --exclude stg_shop__customers` | |

What does `+` before and after a model name mean?

Solution:

| Selection | Models |
|---|---|
| `-s +fct_orders` | `stg_shop__orders`, `stg_payments__transactions`, `int_payments_aggregated_to_orders`, `fct_orders` |
| `-s stg_shop__orders+` | `stg_shop__orders`, `fct_orders`, `dim_customers` |
| `-s staging` | all five staging models |
| `-s source:payments+` | `stg_payments__transactions`, `int_payments_aggregated_to_orders`, `fct_orders`, `dim_customers` |
| `-s +dim_customers --exclude stg_shop__customers` | `stg_shop__orders`, `stg_payments__transactions`, `int_payments_aggregated_to_orders`, `fct_orders`, `dim_customers` |

`+` before selects everything upstream (what the model depends on). `+` after selects everything downstream (what depends on the model).

Note: Without `--resource-type model`, `dbt ls` also lists sources and tests. If you've built bonus models (for example `stg_shop__order_lines`), they show up too.

## `dbt compile` and `dbt show`

`dbt compile` turns your Jinja into the SQL that Snowflake runs, and `dbt show` runs a query and shows the first rows. Neither of them builds anything, so they're safe ways to check your work.

Run:

```
dbt compile -s dim_customers
dbt show -s dim_customers --limit 5
dbt show --inline "select status, count(*) as orders from {{ ref('fct_orders') }} group by status"
```

Where can you see the compiled SQL?
Answer: `target/compiled/publisher_example/models/marts/dim_customers.sql`


When is `dbt compile` useful?
Answer: When you want to see the SQL dbt makes from your Jinja, for example to debug it or copy it to Snowsight, without building anything


## dbt seeds

Seeds are small CSV files in the repo that dbt loads into Snowflake. They're useful for static lookup data that isn't in any source system, such as the Danish public holidays.

Create the following csv file:

`seeds/danish_holidays.csv`:

```csv
holiday_date,holiday_name
2025-01-01,New Year's Day
2025-04-17,Maundy Thursday
2025-04-18,Good Friday
2025-04-20,Easter Sunday
2025-04-21,Easter Monday
2025-05-29,Ascension Day
2025-06-08,Whit Sunday
2025-06-09,Whit Monday
2025-12-25,Christmas Day
2025-12-26,Second Day of Christmas
2026-01-01,New Year's Day
2026-04-02,Maundy Thursday
2026-04-03,Good Friday
2026-04-05,Easter Sunday
2026-04-06,Easter Monday
2026-05-14,Ascension Day
2026-05-24,Whit Sunday
2026-05-25,Whit Monday
2026-12-25,Christmas Day
2026-12-26,Second Day of Christmas
2027-01-01,New Year's Day
2027-03-25,Maundy Thursday
2027-03-26,Good Friday
2027-03-28,Easter Sunday
2027-03-29,Easter Monday
2027-05-06,Ascension Day
2027-05-16,Whit Sunday
2027-05-17,Whit Monday
2027-12-25,Christmas Day
2027-12-26,Second Day of Christmas
```

In `dbt_project.yml`, configure the `holiday_date` column to be a real date:

```yaml
seeds:
  publisher_example:
    danish_holidays:
      +column_types:
        holiday_date: date
```
Now run `dbt seed` (or `dbt build`), and find the data in Snowflake.


## Use the dbt_utils package

Packages let you reuse macros that others have written, and `dbt_utils` is one of the most widely used. Here you use it to give `int_payments_aggregated_to_orders` an amount column per payment method, without a fixed list of methods that has to be updated by hand when a new one shows up:

1. Add `dbt_utils` to `packages.yml`, and run `dbt deps`.
2. Use `dbt_utils.get_column_values`, which fetches the distinct values of a column from the database, to get the payment methods. Then loop over them with `{% for %}` in the `aggregated` CTE, so each method gets its own `<method>_amount_dkk` column.


Solution:

`packages.yml`:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.3.0", "<2.0.0"]
```

At the top of `int_payments_aggregated_to_orders.sql`:

```sql
{%- set payment_methods = dbt_utils.get_column_values(
    table=ref('stg_payments__transactions'),
    column='payment_method',
    order_by='payment_method',
    default=[]
) %}
```

In the `aggregated` CTE, before `sum(amount_dkk) as amount_paid_dkk`:

```sql
        {% for payment_method in payment_methods %}
        sum(case when payment_method = '{{ payment_method }}' then amount_dkk else 0 end) as {{ payment_method }}_amount_dkk,
        {% endfor %}
```

Now every payment method in the data gets its own column. The new method from the daily load (`apple_pay`) is included automatically. The macro runs a query against the database, so `stg_payments__transactions` must be built first.


## Incremental models

A table is rebuilt from scratch on every run, which gets slow and expensive as the data grows. An incremental model only processes the rows that have arrived since the last run.

1. Add `order_lines` to the `shop` source, and build `stg_shop__order_lines`, if you don't have it already.
2. Build `models/marts/fct_order_lines.sql` as an incremental model with a `unique_key`, which only fetches the rows loaded since the last run.
3. Run it twice, and look in the log at what dbt does the second time. Run it again after the daily load, and check the row count.
4. Run it with `--full-refresh`.

<details>
<summary>Solution (click to expand)</summary>

In `_shop__sources.yml` (under `tables:`):

```yaml
      - name: order_lines
```

`models/staging/shop/stg_shop__order_lines.sql`:

```sql
with source as (

    select * from {{ source('shop', 'order_lines') }}

),

renamed as (

    select
        line_id as order_line_id,
        order_no as order_id,
        isbn,
        qty as quantity,
        unit_price_ore / 100 as unit_price_dkk,
        qty * unit_price_ore / 100 as line_amount_dkk,
        _loaded_at

    from source

)

select * from renamed
```

`models/marts/fct_order_lines.sql`:

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_line_id'
    )
}}

with order_lines as (

    select * from {{ ref('stg_shop__order_lines') }}

    {% if is_incremental() %}
    -- Only the rows loaded since the newest row that is already in the table
    where _loaded_at >= (select max(_loaded_at) from {{ this }})
    {% endif %}

),

titles as (

    select * from {{ ref('stg_shop__titles') }}

),

final as (

    select
        order_lines.order_line_id,
        order_lines.order_id,
        order_lines.isbn,
        titles.title,
        titles.format,
        order_lines.quantity,
        order_lines.unit_price_dkk,
        order_lines.line_amount_dkk,
        order_lines._loaded_at

    from order_lines
    left join titles
        on order_lines.isbn = titles.isbn

)

select * from final
```

- The first time, dbt builds the whole table.
- The second time, `is_incremental()` is true: dbt only fetches rows with a `_loaded_at` on or after the newest one in the table, and `merge`s them in on `order_line_id`. Without `unique_key`, the rows would be added again.
- `{{ this }}` is the model's own table.
- `--full-refresh` rebuilds the table from scratch.

Incremental is an optimization, not a starting point: start with a view, switch to a table, and only use incremental when the model is too slow to build.

</details>


## Snapshots

`titles` is fully reloaded every night, so when a price changes, the old price is gone. A snapshot saves every version of a row, so you can see the history afterwards.

1. Create `snapshots/titles_snapshot.yml` with a snapshot of the source `titles`. Use the `timestamp` strategy with `updated_ts`.
2. Run `dbt snapshot` before the daily load. The history starts with your first snapshot, so if you're past the daily load, you'll only see one version per title.
3. After the daily load (the paperbacks are out, so three hardbacks drop 100 DKK in price), run `dbt snapshot` again, and find the titles with two versions.

<details>
<summary>Solution (click to expand)</summary>

`snapshots/titles_snapshot.yml`:

```yaml
snapshots:
  - name: titles_snapshot
    relation: source('shop', 'titles')
    description: Price and in-print history for every title (slowly changing dimension, type 2).
    config:
      unique_key: isbn
      strategy: timestamp
      updated_at: updated_ts
```

```sql
select isbn, title, format, price_ore, dbt_valid_from, dbt_valid_to
from {{ ref('titles_snapshot') }}
where isbn in (
    select isbn
    from {{ ref('titles_snapshot') }}
    group by isbn
    having count(*) > 1
)
order by isbn, dbt_valid_from
```

The hardbacks of *Havet mellem os*, *Den tavse fjord* and *Danmarks glemte øer* now have two rows each: the old price with a `dbt_valid_to`, and the new price, where `dbt_valid_to` is empty.

You take snapshots of **sources**, not of models. History that wasn't saved can't be recreated afterwards.

</details>



## Exposures

Who uses the data? Exposures describe what's downstream of your project, like dashboards and reports, so they show up in the lineage, and you can see what's affected when a model changes.

1. Create `models/marts/_marts__exposures.yml` with an exposure, `sales_dashboard`, for the Power BI dashboard that management and the sales team use. It depends on `fct_orders` and `dim_customers`.
2. Find the exposure in the lineage.
3. Build everything the dashboard depends on: `dbt build -s +exposure:sales_dashboard`.

<details>
<summary>Solution (click to expand)</summary>

```yaml
exposures:
  - name: sales_dashboard
    label: Sales dashboard
    type: dashboard
    maturity: medium
    url: https://app.powerbi.com/
    description: Weekly sales per channel and customer KPIs for management and the sales team, built in Power BI.
    depends_on:
      - ref('fct_orders')
      - ref('dim_customers')
    owner:
      name: BI team
      email: bi@example.com
```

</details>


## dbt Wizard

AI assistants can write tests and documentation in seconds, but you're still responsible for what you commit.

- Install dbt Wizard: https://www.getdbt.com/product/dbt-wizard
- Connect it to your AI provider of choice
- Prompt it to:
  1. suggest tests for `fct_orders`
  2. write descriptions for the columns in `dim_customers`

Review the result critically before you commit:

- Are the tests meaningful, and do they test something that can go wrong?
- Are the descriptions correct, or is the AI guessing from the column name? Do they say anything the column name doesn't already say?
- Run `dbt build`. Does everything pass?

Only commit what you can stand behind yourself. AI-generated code should be reviewed like any other code.
