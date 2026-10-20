with source as (

    select * from {{ source('payments', 'transactions') }}

),

renamed as (

    select
        TRX_ID as transaction_id,
        ORDER_NO as order_id,
        lower(METHOD) as method,
        cast(AMOUNT_ORE * 100 as number(10,2)) as amount_dkk,
        lower(status) as status,
        status = 'OK' as is_successful,
        convert_timezone('UTC', 'Europe/Copenhagen', trx_ts) as created_at,
        _loaded_at as meta_loaded_at,

    from source

)

select * from renamed
