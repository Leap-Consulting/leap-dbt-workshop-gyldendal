# 03 · Tests and `dbt build`

Tests catch bad data before they cause issues.

In this exercise you add tests, fix a real data problem they uncover, and see why production jobs use `dbt build`.

## Task 1: Test the primary keys and the valid values

- create a new file `models/staging/payments/_payments__models.yml` (see `models/staging/shop/_shop__models.yml` for examples)

- add unique and not_null on transaction_id of the stg_payments__transactions model
- add accepted_values on payment_method

- run `dbt test`

## Task 2: Fix the failing test

- Add the following CTE after the `renamed` CTE in `models/staging/shop/stg_shop__customers.sql`, and change the last line to `select * from deduplicated`:

```sql
deduplicated as (

    select * from renamed
    qualify row_number() over (partition by customer_id order by _loaded_at desc) = 1

)
```

- Rebuild the model with `dbt run --select stg_shop__customers`, then run `dbt test` and see that everything is green now

## Task 3: Write a singular test

Singular tests are SQL files that fail if the query returns any rows, and pass when the query returns no rows.

- add the following to a new file `tests/assert_no_orders_in_the_future.sql`:

```sql
-- Orders cannot be placed in the future. The test passes when the query returns no rows.
-- sysdate() is the current time in UTC. Convert it to Danish time, like ordered_at.

select
    order_id,
    ordered_at

from {{ ref('fct_orders') }}
where ordered_at > convert_timezone('UTC', 'Europe/Copenhagen', sysdate())
```

- run `dbt test --select assert_no_orders_in_the_future` and see that the new test is OK


## Task 4: `dbt run` + `dbt test` vs. `dbt build`

1. Temporarily remove `'cancelled'` from the list in `accepted_values` on `status` in `_shop__models.yml`, so the test fails.
2. Run `dbt run` and then `dbt test`. What happens?
3. Now run `dbt build`. Which nodes get the status **SKIP**, and why?
4. Put `'cancelled'` back in the list.


## Task 5: Commit and push

- `git add .`
- `git commit -m "<describe your work>"`
- `git push`

