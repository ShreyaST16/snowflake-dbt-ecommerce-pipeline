select
    o.order_id
from {{ ref('stg_orders') }} o
left join {{ ref('fct_orders') }} f
    on o.order_id = f.order_id
where f.order_id is null