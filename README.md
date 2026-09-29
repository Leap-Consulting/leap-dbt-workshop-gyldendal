# dbt & git workshop · Publisher Example

This repo contains a scaffold dbt project, as well as today's exercises.

## Getting started

Start with [exercise 00 · Setup](exercises/00_setup.md): install the tools, clone the repo and check that dbt can connect to Snowflake.

## Overview of the exercises

| # | Exercise | Type |
|---|---|---|
| 00 | [Setup](exercises/00_setup.md) | Core |
| 01 | [Sources](exercises/01_sources.md) | Core |
| 02 | [Staging, intermediate and marts models](exercises/02_models.md) | Core |
| 03 | [Tests and `dbt build`](exercises/03_tests.md) | Core |
| 04 | [Materialisations](exercises/04_materialisations.md) | Core |
| 05 | [Documentation](exercises/05_documentation.md) | Core |
| – | [Bonus exercises](exercises/99_bonus.md) | Bonus |

The exercises are written for VS Code, with the terminal and the dbt extension.


## Raw data

`RAW` contains these tables:

| Table | Contents |
|---|---|
| `SHOP.IMPRINTS` | 5 imprints |
| `SHOP.TITLES` | 40 titles, one row per edition (ISBN), prices in øre |
| `SHOP.CUSTOMERS` | about 2,000 customers from the web shop and the book club |
| `SHOP.ORDERS` | about 20,000 orders from the last year (timestamps in UTC) |
| `SHOP.ORDER_LINES` | about 50,000 order lines (only used in the bonus exercises) |
| `SHOP.REVIEWS` | reader reviews in Danish (not used in the exercises) |
| `PAYMENTS.TRX_EXPORT_V2` | about 22,000 payments from the payment provider (amounts in øre) |

## Project structure

These are the most important files/folders to know:

```
├── dbt_project.yml          # the project configuration
├── profiles.yml.example     # copy to ~/.dbt/profiles.yml (exercise 00)
├── models/
│   ├── staging/
│   │   ├── shop/            # sources and staging models for the shop system
│   │   └── payments/        # sources and staging models for payments
│   ├── intermediate/        # building blocks: joins and business logic
│   └── marts/               # the finished datasets: fct_ and dim_
├── exercises/               # the exercises
├── leap_internals/          # for instructors only
└── ...
```

## Conventions

- **Everything is in English:** models, columns, sources, macros, descriptions, branch names and commit messages.
- **Model naming:**

  | Layer | Pattern | Example |
  |---|---|---|
  | Staging | `stg_<source>__<entity>` | `stg_shop__orders` |
  | Intermediate | `int_<entity>_<verb>` | `int_payments_aggregated_to_orders` |
  | Marts | `fct_<process>` / `dim_<entity>` | `fct_orders`, `dim_customers` |

- **Branches:** `feat/<short-description>`, for example `feat/workshop-lhk`.
- **Commit messages:** short and in the imperative, for example `Add tests for order_id`.
- **No æ, ø or å in names** of tables and columns (they're fine in the data).

## For instructors

See [leap_internals/INSTRUCTOR_GUIDE.md](leap_internals/INSTRUCTOR_GUIDE.md).

The solutions for each exercise are in `leap_internals/checkpoints/`, and `leap_internals/make_checkpoints.sh` turns them into the branches `checkpoint-01` … `checkpoint-05`.
