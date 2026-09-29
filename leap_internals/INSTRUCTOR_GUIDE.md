# Instructor guide · Publisher Example

> For LEAP instructors only. This folder reveals the planted data quality issues and their solutions. 

## 1. Overview

| File | Purpose |
|---|---|
| `leap_internals/raw_data.sql` | Creates and loads the raw data. |
| `leap_internals/cleanup.sql` | Removes everything after the workshop |
| `leap_internals/checkpoints/` + `leap_internals/make_checkpoints.sh` | The solution files for each exercise, and the script that turns them into the branches `checkpoint-01` … `checkpoint-05` |
| `profiles.yml.example` (repo root) | For participants who work locally in VS Code |

**Branches**
- `main` contains the starter project (two example models and their tests), the pre-work, the exercises and the cheat sheet. The material is written for VS Code.
- `checkpoint-01` … `checkpoint-05` contain the project as it should look after each exercise, and `checkpoint-05` is the finished project. Exercises 2–5 start with the command that catches a participant up from the previous checkpoint. Create the branches with `leap_internals/make_checkpoints.sh` (section 4). If you change a solution in an exercise, change it in `leap_internals/checkpoints/` too.

## 2. Setup and teardown of test data

**Snowflake sample-data setup**
- [ ] Create databases:
  - [ ] RAW
  - [ ] ANALYTICS_DEV
  - [ ] ANALYTICS_PROD
  - [ ] SOLUTION_DEV
  - [ ] SOLUTION_PROD
- [ ] Run `leap_internals/raw_data.sql`. Check the row counts in the last query.

**Cleanup after the workshop**
- [ ] Simply drop the following databases: 
  - [ ] RAW
  - [ ] ANALYTICS_DEV
  - [ ] ANALYTICS_PROD
  - [ ] SOLUTION_DEV
  - [ ] SOLUTION_PROD
- [ ] Also drop any user, role, and/or warehouse created for the workshop

## 4. The planted data quality issues

| # | Issue | Where it shows up | Solution and discussion |
|---|---|---|---|
| 1 | Customer 1042 appears twice in `CUSTOMERS`. The shop system exported the customer again after a move, and ADF appended the row instead of updating it | `unique` on `stg_shop__customers.customer_id` fails (exercise 3, task 2). Also one of the differences in the legacy comparison (exercise 2, bonus b) | Deduplicate in staging with `qualify row_number() … = 1`, and keep the most recently loaded row. In exercise 3, bonus b, the test on the source is set to `warn`, so it still monitors the source |
| 2 | Three orders (20001–20003) point to customer 9999, who doesn't exist | `relationships` fails (exercise 3, bonus a). Show it in plenum at 13.30 | Fix it in the source, filter, or accept? The solution: `severity: warn` and a comment saying it has been reported to the e-commerce team |
| 3 | Last night's load failed. The newest data is 2 days old, and the last load was yesterday at 02.00 UTC | `dbt source freshness` gives `ERROR STALE` (bonus exercise "Source freshness") | Freshness catches it before the users do. After `03_daily_batch.sql`, everything is green |
| 4 | The daily batch contains a new payment method, `apple_pay` | `accepted_values` on `payment_method` fails when participants run their tests after the daily batch (around 13.15) | "Something that was true yesterday isn't true today." Take it in plenum at the start of the 13.30 talk. The solution is to add `apple_pay` to the list (it's a valid method). `checkpoint-03` has it. With the dynamic pivot from exercise 5, `apple_pay` automatically gets its own column, which is a good bridge to Jinja and macros |
| 5 | Timestamps are in UTC | Web orders just after midnight Danish time get the previous day's date if you don't convert | `convert_timezone('UTC', 'Europe/Copenhagen', order_ts)` in staging (exercise 2, task 2). The old script doesn't convert, and that's one of the differences in the legacy comparison (exercise 2, bonus b) |
| 6 | Amounts are in øre | – | Motivates the macro `ore_to_dkk` (exercise 5) |

## 5. (OPTIONAL) Debrief Questions

Exercises 1–5 don't have their own check questions. Ask these at the start of the talk after each exercise, and pick two or three if time is short.

**Exercise 1.1** (10.00)

1. *Why aren't your credentials in git?* Credentials are secret and personal. Everything in git can be seen by everyone with access to the repo, and it stays in the history forever.
2. *Why does every participant have their own schema?* So everyone can develop and test at the same time without overwriting each other's tables. Production builds in its own schema.
3. *Why don't you work directly on `main`?* `main` is what runs in production. Changes should be reviewed and tested first, and that happens in a pull request.

**Exercises 1.2 and 2** (12.15)

1. *What needs to change if the raw databases move or are renamed?* Only `database:` in the two sources files. No models need to be touched.
2. *What's the difference between saving, committing and pushing?* Saving only writes the file on your machine. A commit is a named checkpoint in the history. A push sends your commits to the remote, so others can see them.
3. *Why don't you do joins in staging?* Staging models are building blocks that are 1:1 with the source tables. You clean and rename once, and reuse everywhere. Joins and business logic belong in intermediate and marts, so the logic only exists in one place.
4. *What happens if you run `dbt run --select dim_customers` in a completely empty schema?* It fails, because the models it reads from (`stg_shop__customers` and `fct_orders`) don't exist yet. Run `dbt run --select +dim_customers` instead, so everything upstream is built first.
5. *Why does every model start with import CTEs?* You can see all of a model's inputs at the top, without reading the whole model. The rest of the model only refers to the CTE names, so changing an input only means changing one line.

**Exercise 3** (13.30)

1. *Why does a test fail when its query returns rows?* The test's query looks for the rows that break the assertion. Each row is a concrete example of a problem.
2. *When is `warn` better than `error`?* When the problem is known and can't be fixed right now, but should still be monitored. An `error` stops everything downstream in `dbt build`.
3. *What should you always test, as a minimum?* That the primary key is `unique` and `not_null` in every model.

**Exercises 4 and 5** (14.30)

1. *Who reads the documentation?* Colleagues who will develop the project further, and analysts and business users who need to understand what a field means and where a number comes from.
2. *When is a doc block better than a plain description?* When the same explanation is needed in several places, or when it's long (tables, lists). Then it's only changed in one place.
3. *When does Jinja make the code harder to read?* When there's so much logic that you can't see which SQL comes out without compiling it. Loops inside loops and macros that call macros are typical examples.
4. *Where's the line between DRY ("don't repeat yourself") and readability?* Use Jinja when it removes real repetition or prevents mistakes, as with the pivot and the øre conversion. If the SQL is short and clear already, leave it as plain SQL. The next person reading the code should be able to understand it.
