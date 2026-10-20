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
),

deduplicated as (

    select * from renamed
    qualify row_number() over (partition by customer_id order by _loaded_at desc) = 1

)

select * from deduplicated
