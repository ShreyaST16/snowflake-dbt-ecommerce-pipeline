with source as (

    select *
    from {{ source('novamart', 'products') }}

),

cleaned as (

    select
        product_id,
        trim(product_name) as product_name,
        initcap(trim(category)) as category,
        unit_price

    from source

)

select *
from cleaned