with source as (

    select 'TODO' -- TODO: reference the source you defined

),

renamed as (

    select
        'TODO' as todo_column, -- TODO: standardization and simple cleaning
        lower(status) as status,
        status = 'OK' as is_successful,
        convert_timezone('UTC', 'Europe/Copenhagen', trx_ts) as created_at,
        _loaded_at

    from source

)

select * from renamed
