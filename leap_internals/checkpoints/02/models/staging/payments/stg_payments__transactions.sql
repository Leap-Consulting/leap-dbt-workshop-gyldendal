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
