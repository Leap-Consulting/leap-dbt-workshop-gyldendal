with source as (
    select * from {{ source('shop', 'orders' ) }}
),

renamed as (

    select
        order_no as order_id,
        cust_no as customer_id,
        cast(convert_timezone('UTC', 'Europe/Copenhagen', order_ts) as date)
            as order_date,
        _loaded_at,
        convert_timezone('UTC', 'Europe/Copenhagen', order_ts) as ordered_at,
        case
            when status_cd = 'P' then 'placed'
            when status_cd = 'S' then 'shipped'
            when status_cd = 'D' then 'delivered'
            when status_cd = 'X' then 'cancelled'
        end as status,
        lower(channel) as channel
    from source

)

select * from renamed
