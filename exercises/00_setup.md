# 00 · Setup

In this exercise you get everything in place for the rest of the day: Visual Studio Code (VS Code), your own copy of the project, your own branch, and a connection from dbt to Snowflake.

## Task 1: Install the tools

1. Download and install the following three programs, unless they're already installed on your computer:

- Visual Studio Code from https://code.visualstudio.com
- git: https://git-scm.com/install
- uv: https://docs.astral.sh/uv/getting-started/installation/

## Task 2: Clone the repo and create a new branch

1. Run `git clone git@github.com:Leap-Consulting/leap-dbt-workshop-gyldendal.git` in your terminal
2. Open the cloned folder in VS Code, and run `git checkout -b feat/workshop-<your initials>` in the terminal


## Task 3: Install and configure dbt and the dbt Power User extension

1. Setup your python environment by running `uv sync` in a terminal open in your cloned folder
2. Open the cloned folder in VS Code
3. Install the "Power User for dbt" extension (VS Code should show a popup in the bottom right after a while, recommending this extension)


## Task 3: Set up development credentials

1. Copy `profiles.yml.example` to `C:\Users\<your username>\.dbt\profiles.yml` (create the `.dbt` folder if it doesn't exist)
   - If you already have a `profiles.yml` file there, then copy the contents of `profiles.yml.example` to the bottom of this file.

2. Edit the following fields in the inserted text of `profiles.yml`:
   - `user`: your username
   - `password`: your provided password
   - `schema`: `dbt_<your initials>`


## Task 4: Check the connection

Run `dbt debug` to test your connection.

