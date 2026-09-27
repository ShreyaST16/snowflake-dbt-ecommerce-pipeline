with source as (

    select *
    from {{ source('novamart', 'customers') }}

),

cleaned as (

    select
        customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,

        case
            when upper(trim(state)) in ('TX', 'TEXAS') then 'TX'
            when upper(trim(state)) in ('CA', 'CALIFORNIA') then 'CA'
            when upper(trim(state)) in ('NY', 'NEW YORK') then 'NY'
            else upper(trim(state))
        end as state,

        created_at

    from source

)

select *
from cleaned