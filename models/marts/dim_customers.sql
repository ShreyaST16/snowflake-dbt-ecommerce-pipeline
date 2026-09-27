with customers as (

    select *
    from {{ ref('stg_customers') }}

),

orders as (

    select *
    from {{ ref('fct_orders') }}

),

customer_metrics as (

    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(*) as total_orders,
        sum(case when order_status = 'COMPLETED' then order_amount else 0 end) as lifetime_value

    from orders

    group by customer_id

),

final as (

    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.state,
        c.created_at,
        m.first_order_date,
        m.last_order_date,
        coalesce(m.total_orders, 0) as total_orders,
        coalesce(m.lifetime_value, 0) as lifetime_value

    from customers c

    left join customer_metrics m
        on c.customer_id = m.customer_id

)

select *
from final