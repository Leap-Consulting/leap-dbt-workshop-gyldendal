with source as (

    select * from {{ source('shop', 'orders') }}

),

renamed as (

    select
        order_no as order_id,
        cust_no as customer_id,
        convert_timezone('UTC', 'Europe/Copenhagen', order_ts) as ordered_at,
        cast(convert_timezone('UTC', 'Europe/Copenhagen', order_ts) as date) as order_date,
        case status_cd
            when 'P' then 'placed'
            when 'S' then 'shipped'
            when 'D' then 'delivered'
            when 'X' then 'cancelled'
        end as status,
        lower(channel) as channel,
        _loaded_at

    from source

)

select * from renamed
