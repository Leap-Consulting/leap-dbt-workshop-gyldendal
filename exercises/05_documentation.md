# 05 · Documentation

In dbt, the documentation lives in YAML files next to the code, so it's versioned and reviewed like the code, and dbt turns it into a website with descriptions and lineage. In this exercise you describe the marts, and explore them in the generated documentation.

## Task 1: Add some descriptions

- In `models/marts/_marts__models.yml`, replace the TODOs with your own descriptions:

```yaml
models:
  - name: fct_orders
    description: "TODO" # TODO: add a model description here
    columns:
      - name: order_id
        description: "TODO" # TODO: describe the order_id column here
        data_tests:
          - unique
          - not_null
      - name: ordered_at
        #description: "optionally add a description to this column"
      - name: status
        #description: "optionally add a description to this column"
      - name: amount_paid_dkk
        #description: "optionally add a description to this column"

  # if you feel like it, you can also add some descriptions to dim_customers!

```

## Task 2: Generate and explore the documentation

- Run `dbt docs generate`
- Run `dbt docs serve` to open the generated documentation in your browser
- Navigate to the fct_orders model, and view your description of the model, as well as the description you wrote for the order_id column


## Task 3: Commit and push

- `git add .`
- `git commit -m "<describe your work>"`
- `git push`
