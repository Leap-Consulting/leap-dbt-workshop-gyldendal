with transactions as (

    select * from {{ ref('stg_payments__transactions') }} -- TODO: reference the payments staging model

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
