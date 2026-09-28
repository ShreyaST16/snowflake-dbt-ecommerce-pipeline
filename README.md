# NovaMart Analytics Engineering Pipeline

An end-to-end analytics engineering project built with **Snowflake + dbt Core**.

The project models raw e-commerce data into trusted analytics-ready datasets using a layered ELT architecture, automated data-quality tests, dimensional modeling, and incremental processing.

## Project goals

NovaMart is a fictional e-commerce company with source data for:

- customers
- products
- orders
- order items
- payments

The goal is to transform raw operational data into reliable datasets that can support questions such as:

- How much revenue was generated?
- Which customers have the highest lifetime value?
- Which products are being purchased?
- How many orders were completed or cancelled?
- What is the average value of an order?

## Tech stack

- **Snowflake** — cloud data warehouse and compute
- **dbt Core** — SQL transformations, testing, documentation, lineage
- **SQL** — transformation and dimensional modeling
- **Git / GitHub** — version control and project documentation

## Architecture

```mermaid
flowchart TD
    A[CSV Source Files] --> B[Snowflake RAW]
    B --> C[dbt Staging Views]
    C --> D[dbt Intermediate Views]
    D --> E[dbt Marts]
    E --> F[Analytics / BI Consumers]

    B1[RAW.CUSTOMERS] --> C1[STG_CUSTOMERS]
    B2[RAW.PRODUCTS] --> C2[STG_PRODUCTS]
    B3[RAW.ORDERS] --> C3[STG_ORDERS]
    B4[RAW.ORDER_ITEMS] --> C4[STG_ORDER_ITEMS]
    B5[RAW.PAYMENTS] --> C5[STG_PAYMENTS]

    C2 --> D1[INT_ORDER_ITEMS_ENRICHED]
    C3 --> D1
    C4 --> D1
    C5 --> D2[INT_PAYMENTS_BY_ORDER]

    C3 --> E1[FCT_ORDERS]
    D1 --> E1
    D2 --> E1
    C1 --> E2[DIM_CUSTOMERS]
    E1 --> E2
    C2 --> E3[DIM_PRODUCTS]
```

## Layered design

| Layer | Purpose | Materialization |
|---|---|---|
| `RAW` | Preserve source data with minimal transformation | Tables |
| `STAGING` | Clean, standardize, rename, and validate individual source tables | Views |
| `INTERMEDIATE` | Reusable joins and business logic across staging models | Views |
| `MARTS` | Analytics-ready fact and dimension models | Tables / Incremental |

This design is conceptually similar to a medallion architecture:

- `RAW` ≈ Bronze
- `STAGING` + `INTERMEDIATE` ≈ Silver
- `MARTS` ≈ Gold

The mapping is conceptual rather than a strict one-to-one implementation.

## Data model

### Fact table

**`FCT_ORDERS`**

**Grain:** one row per order.

Contains:

- order identifiers
- customer identifiers
- order date and status
- total item count
- order amount
- net payment amount
- last payment timestamp
- payment transaction count

### Dimensions

**`DIM_CUSTOMERS`**

**Grain:** one row per customer.

Includes standardized customer attributes plus:

- first order date
- last order date
- total orders
- lifetime value

**`DIM_PRODUCTS`**

**Grain:** one row per product.

Contains standardized product attributes such as category and unit price.

## dbt model lineage

```text
RAW.CUSTOMERS
    ↓
STG_CUSTOMERS ───────────────────────────────→ DIM_CUSTOMERS
                                                   ↑
                                                   │
RAW.ORDERS                                         │
    ↓                                              │
STG_ORDERS ───────────────────────────────────→ FCT_ORDERS
                                                   ↑
RAW.ORDER_ITEMS                                    │
    ↓                                              │
STG_ORDER_ITEMS ──┐                                │
                  ├──→ INT_ORDER_ITEMS_ENRICHED ───┤
RAW.PRODUCTS      │                                │
    ↓             │                                │
STG_PRODUCTS ─────┘                                │
    │                                              │
    └──────────────────────────────────────────→ DIM_PRODUCTS
                                                  │
RAW.PAYMENTS                                      │
    ↓                                             │
STG_PAYMENTS                                      │
    ↓                                             │
INT_PAYMENTS_BY_ORDER ────────────────────────────┘
```

## Data quality

The project uses dbt data tests to validate assumptions such as:

- primary identifiers are not null
- primary identifiers are unique
- order customer IDs exist in the customer model
- order item order IDs exist in the order model
- order item product IDs exist in the product model
- payment order IDs exist in the order model
- order status values are restricted to expected values
- payment status values are restricted to expected values
- every staged order must exist in `FCT_ORDERS`
- completed order amounts must reconcile to net payment amounts

Examples include:

```yaml
data_tests:
  - not_null
  - unique
```

and:

```yaml
data_tests:
  - relationships:
      arguments:
        to: ref('stg_customers')
        field: customer_id
```

The project also includes singular reconciliation tests:

- `assert_all_orders_in_fact.sql` verifies that no staged orders disappear from the fact table
- `assert_paid_orders_reconcile.sql` verifies that completed order amounts reconcile to net payment amounts

A singular dbt test passes when its query returns zero rows.

## Incremental processing

`FCT_ORDERS` is implemented as an incremental dbt model.

Conceptually:

```text
existing FCT_ORDERS
        +
new qualifying source orders
        ↓
incremental dbt run
        ↓
updated FCT_ORDERS
```

The project uses `order_id` as the unique key with Snowflake `MERGE` behavior so qualifying rows can be inserted or updated without rebuilding the entire fact table.

For this demo, incremental runs reprocess a 3-day `order_date` lookback window. This helps catch some late-arriving changes while keeping the example simple and efficient.

## Project Screenshots

### dbt Lineage

The dbt DAG shows the dependency flow from Snowflake source tables through staging and intermediate models into analytics-ready marts.

![dbt lineage](docs/DBT_Data_Lineage_Graph.png)

### Fact Table Structure

`FCT_ORDERS` is materialized in Snowflake with one row per order.

![fct_orders structure](docs/fct_orders_structure.png)

### Fact Table Sample Data

Sample rows from the final fact table.

![fct_orders sample data](docs/fct_orders_sample_data.png)

### Customer Dimension

![dim_customers structure](docs/dim_customers_structure.png)

![dim_customers sample data](docs/dim_customers_data.png)

### Product Dimension

![dim_products structure](docs/dim_products_structure.png)

![dim_products sample data](docs/dim_products_data.png)

### Production consideration

A production pipeline would usually use a more robust change-detection strategy such as:

- source `updated_at` timestamps
- change data capture (CDC)
- watermarks
- configurable lookback windows
- merge/upsert logic

These patterns improve detection of late-arriving records and updates to historical orders.

## dbt concepts demonstrated

This project demonstrates:

- `source()`
- `ref()`
- model dependencies
- DAG / lineage
- staging models
- intermediate models
- marts
- views
- tables
- incremental models
- schema routing
- custom macros
- dbt generic tests
- dimensional modeling
- referential integrity
- ELT architecture
- role-based access control (RBAC)

## Repository structure

```text
novamart/
│
├── dbt_project.yml
│
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── schema.yml
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_order_items.sql
│   │   └── stg_payments.sql
│   │
│   ├── intermediate/
│   │   ├── int_order_items_enriched.sql
│   │   └── int_payments_by_order.sql
│   │
│   └── marts/
│       ├── schema.yml
│       ├── fct_orders.sql
│       ├── dim_customers.sql
│       └── dim_products.sql
│
├── macros/
│   └── generate_schema_name.sql
│
├── tests/
│   ├── assert_all_orders_in_fact.sql
│   └── assert_paid_orders_reconcile.sql
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   ├── orders.csv
│   ├── order_items.csv
│   └── payments.csv
│
├── setup/
│   ├── create_raw_objects.sql
│   ├── create_transformer_role.sql
│   └── load_raw.sql
│
├── docs/
│   ├── DBT_Data_Lineage_Graph.png
│   ├── fct_orders_structure.png
│   ├── fct_orders_sample_data.png
│   ├── dim_customers_structure.png
│   ├── dim_customers_data.png
│   ├── dim_products_structure.png
│   └── dim_products_data.png
│
├── profiles.yml.example
├── requirements.txt
├── .gitignore
└── README.md
```

## Local setup

### 1. Create and activate a Python virtual environment

Windows:

```bash
python -m venv .venv
.venv\Scripts\activate.bat
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Create the Snowflake raw layer

Run:

```text
setup/create_raw_objects.sql
```

This creates the required schemas, CSV file format, internal Snowflake stage, and raw source tables.

### 4. Create the dbt transformer role

Run:

```text
setup/create_transformer_role.sql
```

This creates a dedicated `TRANSFORMER` role with the permissions needed to:

- use the project warehouse
- read from `RAW`
- create tables and views in `STAGING`, `INTERMEDIATE`, and `MARTS`

Grant the role to the Snowflake user that will run dbt.

The ownership-transfer statements used while migrating an existing environment are intentionally not included in the setup script. In a clean setup, dbt-created objects are owned by the role that creates them.

### 5. Upload the synthetic source files

Upload the files from:

```text
data/
```

to:

```text
@NOVAMART_DB.RAW.NOVAMART_STAGE
```

using Snowsight, SnowSQL, or Snowflake CLI.

Files included:

- `customers.csv`
- `products.csv`
- `orders.csv`
- `order_items.csv`
- `payments.csv`

### 6. Load the raw tables

After the files are staged, run:

```text
setup/load_raw.sql
```

This uses Snowflake `COPY INTO` commands to populate the raw source tables.

### 7. Configure the dbt profile

Copy:

```text
profiles.yml.example
```

to your local dbt profiles directory:

```text
C:\Users\<your-user>\.dbt\profiles.yml
```

The example profile uses:

```text
role: TRANSFORMER
```

and expects the Snowflake programmatic access token through the environment variable:

```text
SNOWFLAKE_PAT
```

Do not commit credentials, tokens, or your real `profiles.yml` to GitHub.

### 8. Validate the connection

```bash
dbt debug
```

### 9. Build and test the project

```bash
dbt build
```

This builds the models in dependency order and runs the configured data tests.

### 10. Run only the marts

```bash
dbt build --select path:models/marts
```

## Example commands

Build a single model:

```bash
dbt run --select stg_customers
```

Run staging models:

```bash
dbt run --select path:models/staging
```

Run tests:

```bash
dbt test
```

Run the incremental fact:

```bash
dbt run --select fct_orders
```

Force a full rebuild of the incremental model:

```bash
dbt run --select fct_orders --full-refresh
```

## Key design decisions

**Why views for staging?**  
Staging transformations are lightweight, and views automatically reflect changes in the raw source tables without requiring a physical rebuild.

**Why an intermediate layer?**  
It keeps reusable joins and transformation logic out of final marts and prevents repeated SQL across downstream models.

**Why a fact/dimension mart?**  
It gives analytics consumers a clear business-oriented model with explicitly defined grain.

**Why incremental processing?**  
It avoids rebuilding the entire fact table when only a small amount of new or recently changed data arrives. The model uses a 3-day lookback window and `order_id` as the merge key.

**Why a dedicated `TRANSFORMER` role?**  
dbt runs with a project-specific role instead of `ACCOUNTADMIN`, limiting access to only the warehouse, raw source reads, and object creation needed for this pipeline.

## What I learned

This project reinforced practical understanding of:

- the difference between ETL and ELT
- how Snowflake separates storage and compute
- how dbt manages transformations inside a warehouse
- how `source()` differs from `ref()`
- why grain matters in fact-table design
- how referential integrity can be tested in dbt
- why staging models are often materialized as views
- how incremental models reduce unnecessary recomputation
- how layered data architecture maps to Bronze / Silver / Gold concepts

## Future improvements

Possible extensions:

- add CI with GitHub Actions
- add source freshness checks
- add audit columns such as `loaded_at`
- replace the demo `order_date` lookback with source `updated_at` or CDC for production-grade change detection
- add snapshots for slowly changing dimensions
- add a BI dashboard
- add orchestration with Airflow
- add ingestion using Fivetran or Airbyte

---

Built as a portfolio project to demonstrate practical analytics engineering and modern cloud data transformation patterns.
