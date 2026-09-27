with source as (

    select *
    from {{ source('novamart', 'order_items') }}

),

cleaned as (

    select
        order_id,
        product_id,
        quantity,
        unit_price,
        quantity * unit_price as line_amount

    from source

)

select *
from cleaned