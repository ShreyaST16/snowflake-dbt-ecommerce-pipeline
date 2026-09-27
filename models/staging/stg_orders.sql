with source as (

    select *
    from {{ source('novamart', 'orders') }}

),

cleaned as (

    select
        order_id,
        customer_id,
        order_date,

        case
            when upper(trim(status)) in ('COMPLETE', 'COMPLETED') then 'COMPLETED'
            when upper(trim(status)) = 'CANCELLED' then 'CANCELLED'
            else upper(trim(status))
        end as order_status

    from source

)

select *
from cleaned