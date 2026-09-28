select
    order_id,
    order_amount,
    net_payment_amount
from {{ ref('fct_orders') }}
where order_status = 'COMPLETED'
  and abs(coalesce(order_amount, 0) - coalesce(net_payment_amount, 0)) > 0.01