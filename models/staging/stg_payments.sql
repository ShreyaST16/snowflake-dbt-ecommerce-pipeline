with source as (

    select *
    from {{ source('novamart', 'payments') }}

),

cleaned as (

    select
        payment_id,
        order_id,
        lower(trim(payment_method)) as payment_method,

        case
            when upper(trim(payment_status)) = 'PAID' then 'PAID'
            when upper(trim(payment_status)) = 'REFUNDED' then 'REFUNDED'
            else upper(trim(payment_status))
        end as payment_status,

        amount as payment_amount,
        paid_at

    from source

)

select *
from cleaned