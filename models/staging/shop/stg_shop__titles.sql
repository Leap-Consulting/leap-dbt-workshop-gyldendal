-- Staging model: one row per title (one ISBN per edition).
-- Removes the hyphens from the ISBN, so it matches the order lines, converts
-- prices from øre to DKK and turns the Y/N flag into a boolean.

with source as (

    select * from {{ source('shop', 'titles') }}

),

renamed as (

    select
        title,
        author,
        imprint_id,
        format,
        updated_ts as updated_at,
        _loaded_at,
        replace(isbn, '-', '') as isbn,
        price_ore / 100 as price_dkk,
        in_print_flag = 'Y' as is_in_print

    from source

)

select * from renamed
