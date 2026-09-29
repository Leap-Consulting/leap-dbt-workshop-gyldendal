-- Staging model: one row per imprint, with clear column names and types.
-- The pattern used in every staging model:
--   1. import the source in a CTE
--   2. rename and cast in a second CTE
--   3. select from the last CTE

with source as (

    select * from {{ source('shop', 'imprints') }}

),

renamed as (

    select
        imprint_id,
        imprint_name,
        genre,
        cast(founded_date as date) as founded_date,
        _loaded_at

    from source

)

select * from renamed
