with orders as (

    select * from {{ ref('stg_orders') }} -- TODO: reference the orders staging model

),

payments as (

    select * from {{ ref('int_payments_aggregated_to_orders') }} -- TODO: reference the intermediate model

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
