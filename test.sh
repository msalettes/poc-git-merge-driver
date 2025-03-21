#!/bin/bash
set -e

git checkout -b feature-a

yarn
git add package.json yarn.lock
gcmsg 'chore: upgrade react-router'

# Go back to master and create feature-b
git checkout main
git checkout -b feature-b

yarn
git add package.json yarn.lock
gcmsg 'chore: upgrade react-intl'

# Merge feature-b into feature-a
git checkout feature-a
