with source as (

    select * from {{source('payments', 'trx_export_v2') }}  -- TODO: reference the source you defined

),

renamed as (

    select
      trx_id as transaction_id, -- TODO: standardization and simple cleaning
        order_no as order_id,
        lower(method) as payment_method,
        lower(status) as status,
        CAST(amount_ore as number(10,2)) as amount_dkk,
        status = 'OK' as is_successful,
        convert_timezone('UTC', 'Europe/Copenhagen', trx_ts) as created_at,
        _loaded_at

    from source

)

select * from renamed
