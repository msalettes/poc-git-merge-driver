#!/usr/bin/env node

const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Get file paths from Git merge driver arguments
const [ancestorPath, currentPath, otherPath, marker] = process.argv.slice(2);

try {
  // First, ensure that package.json is properly merged
  // The yarn-lock driver should be run AFTER the package-json driver

  // Get the directory containing the yarn.lock file
  const repoRoot = path.dirname(currentPath);

  // Backup the current yarn.lock
  const backupPath = `${currentPath}.backup`;
  fs.copyFileSync(currentPath, backupPath);

  console.log('Regenerating yarn.lock file from the merged package.json...');

  try {
    // Execute yarn to regenerate the lockfile
    execSync('yarn install --force', {
      cwd: repoRoot,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    console.log('Successfully regenerated yarn.lock file');
    process.exit(0); // Success
  } catch (error) {
    console.error('Error running yarn install:', error);

    // Restore backup on error
    console.log('Restoring yarn.lock from backup...');
    fs.copyFileSync(backupPath, currentPath);

    process.exit(1); // Let Git handle the conflict
  } finally {
    // Clean up backup file
    if (fs.existsSync(backupPath)) {
      fs.unlinkSync(backupPath);
    }
  }
} catch (error) {
  console.error('Error in yarn.lock merge driver:', error);
  process.exit(1); // Failure, let Git handle it
}
