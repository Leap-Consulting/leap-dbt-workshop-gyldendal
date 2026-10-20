{{ config(materialized='view') }}

with customers as (

    select * from {{ ref('stg_shop__customers') }} -- TODO: reference the customers staging model

),

orders as (

    select * from {{ ref('fct_orders') }} -- TODO: reference the fct_orders model

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
