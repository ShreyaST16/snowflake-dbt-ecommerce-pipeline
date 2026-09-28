with payments as (

    select *
    from {{ ref('stg_payments') }}

),

aggregated as (

    select
        order_id,

        sum(
            case
                when payment_status = 'PAID' then payment_amount
                when payment_status = 'REFUNDED' then -payment_amount
                else 0
            end
        ) as net_payment_amount,

        max(paid_at) as last_payment_at,

        count(*) as payment_transaction_count

    from payments

    group by order_id

)

select *
from aggregated