with order_items as (

    select *
    from {{ ref('stg_order_items') }}

),

orders as (

    select *
    from {{ ref('stg_orders') }}

),

products as (

    select *
    from {{ ref('stg_products') }}

),

joined as (

    select
        oi.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        oi.product_id,
        p.product_name,
        p.category,
        oi.quantity,
        oi.unit_price,
        oi.line_amount

    from order_items oi

    inner join orders o
        on oi.order_id = o.order_id

    inner join products p
        on oi.product_id = p.product_id

)

select *
from joined