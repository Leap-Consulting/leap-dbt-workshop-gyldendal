-- Orders cannot be placed in the future. The test passes when the query returns no rows.
-- sysdate() is the current time in UTC. Convert it to Danish time, like ordered_at.

select
    order_id,
    ordered_at

from {{ ref('fct_orders') }}
where ordered_at > convert_timezone('UTC', 'Europe/Copenhagen', sysdate())
