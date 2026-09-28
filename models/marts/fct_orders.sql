{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

with orders as (

    select *
    from {{ ref('stg_orders') }}

    {% if is_incremental() %}
    where order_date >= (
        select dateadd(day, -3, max(order_date))
        from {{ this }}
    )
    {% endif %}

),

order_items as (

    select
        order_id,
        sum(quantity) as total_items,
        sum(line_amount) as order_amount
    from {{ ref('int_order_items_enriched') }}
    group by order_id

),

payments as (

    select *
    from {{ ref('int_payments_by_order') }}

),

final as (

    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,

        coalesce(i.total_items, 0) as total_items,
        coalesce(i.order_amount, 0) as order_amount,

        p.net_payment_amount,
        p.last_payment_at,
        p.payment_transaction_count

    from orders o

    left join order_items i
        on o.order_id = i.order_id

    left join payments p
        on o.order_id = p.order_id

)

select *
from final