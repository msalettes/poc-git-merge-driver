# Git Merge Drivers for Package.json and Yarn.lock

Custom Git merge drivers to handle conflicts in `package.json` and `yarn.lock` files, especially for `@mirakl/*` dependencies.

## Features

- **Package.json merge driver**: Automatically resolves version conflicts by selecting the higher version, particularly for `@mirakl/*` dependencies.
- **Yarn.lock merge driver**: Regenerates the yarn.lock file after the package.json has been successfully merged.

## Installation

1. Install the required dependencies:

```bash
npm install semver --save-dev
```

2. Run the setup script:

```bash
node setup.js
```

This will:
- Configure Git to use the custom merge drivers
- Create or update your repository's `.gitattributes` file
- Make the scripts executable

## How It Works

When Git encounters a merge conflict in `package.json` or `yarn.lock`:

1. For `package.json`:
   - The driver compares the versions from both branches
   - For conflicting versions, it selects the higher version number
   - For `@mirakl/*` dependencies, it ensures the latest version is used

2. For `yarn.lock`:
   - The driver runs `yarn install --force` to regenerate the lock file based on the merged `package.json`

## Manual Setup (if needed)

Add these lines to your global Git config (`~/.gitconfig`):

