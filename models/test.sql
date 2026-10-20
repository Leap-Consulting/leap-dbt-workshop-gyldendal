select * from {{ source('payments', 'trx_export_v2') }}
