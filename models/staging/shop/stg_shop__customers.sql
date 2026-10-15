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
        convert_timezone('UTC', 'Europe/Copenhagen', created_ts) as created_at,
        _loaded_at

    from source

),

-- The shop system sometimes re-exports a customer, and the nightly load appends
-- the new row. Keep only the most recently loaded row per customer.
deduplicated as (

    select * from renamed
    qualify row_number() over (partition by customer_id order by _loaded_at desc) = 1

)

select * from deduplicated
