#!/usr/bin/env bash
# =====================================================================
# Publisher Example · checkpoint branches
#
# Creates the branches checkpoint-01 … checkpoint-05: the project as it
# should look after each exercise. Participants who fall behind catch up
# with the command at the top of exercises 2–5, for example:
#   git fetch
#   git checkout origin/checkpoint-02 -- models tests macros packages.yml dbt_project.yml
#
# Each checkpoint is the base branch plus the files in
# leap_internals/checkpoints/01 up to and including that exercise.
# leap_internals/ itself is left out of the branches, and your working
# tree isn't touched.
#
# Usage (from the repo root), with main as the default base:
#   ./leap_internals/make_checkpoints.sh [<base>]
#   git push --force origin checkpoint-01 checkpoint-02 checkpoint-03 checkpoint-04 checkpoint-05
#
# Run it again whenever the base branch or the solutions change.
# =====================================================================
set -euo pipefail

base="${1:-main}"
checkpoints="$(cd "$(dirname "$0")" && pwd)/checkpoints"
tmp="$(mktemp -d)"
worktree="$tmp/worktree"

git worktree add --quiet --detach "$worktree" "$base"
trap 'git worktree remove --force "$worktree"; rm -rf "$tmp"' EXIT

git -C "$worktree" rm -r --quiet --ignore-unmatch leap_internals

for dir in "$checkpoints"/[0-9][0-9]; do
  exercise="$(basename "$dir")"
  cp -R "$dir"/. "$worktree"
  git -C "$worktree" add --all
  git -C "$worktree" commit --quiet --no-verify --allow-empty -m "Checkpoint after exercise $exercise"
  git -C "$worktree" branch --force "checkpoint-$exercise"
  echo "checkpoint-$exercise"
done
