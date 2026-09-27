with order_items as (

    select *
    from {{ ref('int_order_items_enriched') }}

),

payments as (

    select *
    from {{ ref('stg_payments') }}

),

order_summary as (

    select
        order_id,
        customer_id,
        order_date,
        order_status,

        sum(quantity) as total_items,
        sum(line_amount) as order_amount

    from order_items

    group by
        order_id,
        customer_id,
        order_date,
        order_status

),

final as (

    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.total_items,
        o.order_amount,
        p.payment_method,
        p.payment_status,
        p.payment_amount,
        p.paid_at

    from order_summary o

    left join payments p
        on o.order_id = p.order_id

)

select *
from final