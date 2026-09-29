# 02 · Staging, intermediate and marts models

dbt projects are built in layers: staging models clean up one source table each, intermediate models are reusable building blocks, and marts are the finished tables that people use. In this exercise you build the staging model for the payments, and connect it all the way to `fct_orders` and `dim_customers` with `ref()`.


## Task 1: Create your first model

Open `models/staging/payments/stg_payments__transactions.sql`, and replace the TODOs, so the model does the following:

- stage your source
- rename trx_id -> transaction_id
- rename order_no -> order_id
- lowercase 'method' and rename to payment_method
- convert amount_ore to kroner (1 kr = 100 øre) and rename to amount_dkk
- cast amount_dkk to number(10, 2), so it has 2 decimals instead of 6

<details>
<summary>Solution (click to expand)</summary>

```sql
with source as (

    select * from {{ source('payments', 'trx_export_v2') }}

),

renamed as (

    select
        trx_id as transaction_id,
        order_no as order_id,
        lower(method) as payment_method,
        cast(amount_ore / 100 as number(10, 2)) as amount_dkk,
        lower(status) as status,
        status = 'OK' as is_successful,
        convert_timezone('UTC', 'Europe/Copenhagen', trx_ts) as created_at,
        _loaded_at

    from source

)

select * from renamed
```

</details>

Run `dbt run --select staging`. It runs all staging models, including the one you just added.


## Task 2: Fix the references in the int and marts models

- Fix the references in `models/intermediate/int_payments_aggregated_to_orders.sql`, `models/marts/fct_orders.sql` and `models/marts/dim_customers.sql`

<details>
<summary>Solution (click to expand)</summary>

`models/intermediate/int_payments_aggregated_to_orders.sql`:

```sql
with transactions as (

    select * from {{ ref('stg_payments__transactions') }}

),

successful as (

    select * from transactions
    where is_successful

),

aggregated as (

    select
        order_id,
        sum(amount_dkk) as amount_paid_dkk,
        count(*) as payment_count

    from successful
    group by order_id

)

select * from aggregated
```

`models/marts/fct_orders.sql`:

```sql
with orders as (

    select * from {{ ref('stg_shop__orders') }}

),

payments as (

    select * from {{ ref('int_payments_aggregated_to_orders') }}

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.ordered_at,
        orders.order_date,
        orders.status,
        orders.channel,
        coalesce(payments.amount_paid_dkk, 0) as amount_paid_dkk,
        coalesce(payments.payment_count, 0) as payment_count

    from orders
    left join payments
        on orders.order_id = payments.order_id

)

select * from final
```

`models/marts/dim_customers.sql`:

```sql
with customers as (

    select * from {{ ref('stg_shop__customers') }}

),

orders as (

    select * from {{ ref('fct_orders') }}

),

customer_orders as (

    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(*) as number_of_orders,
        sum(amount_paid_dkk) as lifetime_value_dkk

    from orders
    where status != 'cancelled'
    group by customer_id

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers.email,
        customers.zip_code,
        customer_orders.first_order_date,
        customer_orders.most_recent_order_date,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders,
        coalesce(customer_orders.lifetime_value_dkk, 0) as lifetime_value_dkk

    from customers
    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

)

select * from final
```

</details>


## Task 3: dbt run and view lineage

- Run `dbt run` to build all the models
- Open `models/marts/dim_customers.sql`, and look at its lineage in the dbt extension


## Task 4: Commit and push

- `git add .`
- `git commit -m "<describe your work>"`
- `git push`
