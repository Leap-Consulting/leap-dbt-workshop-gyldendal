with source as (
    select * from {{ source('shop', 'customers') }}
),

renamed as (
    select
        cust_no as customer_id,
        first_name,
        last_name,
        lower(trim(email)) as email,
        zip_code,
        convert_timezone('UTC', 'Europe/Copenhagen', created_ts)
            as created_at,
        _loaded_at
    from source
)

select * from renamed
