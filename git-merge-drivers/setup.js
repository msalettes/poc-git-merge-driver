#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Make the driver scripts executable
execSync('chmod +x package-json-merge-driver.js yarn-lock-merge-driver.js', {
    cwd: __dirname,
});

// Get absolute paths to the drivers
const packageJsonDriverPath = path.resolve(
    __dirname,
    'package-json-merge-driver.js'
);
const yarnLockDriverPath = path.resolve(__dirname, 'yarn-lock-merge-driver.js');

// Install the merge drivers
try {
    // Define the merge driver for package.json files
    execSync(
        `git config --global merge.package-json-driver.driver "${packageJsonDriverPath} %O %A %B %P"`
    );
    execSync(
        'git config --global merge.package-json-driver.name "Custom merge driver for package.json files"'
    );

    // Define the merge driver for yarn.lock files
    execSync(
        `git config --global merge.yarn-lock-driver.driver "${yarnLockDriverPath} %O %A %B %P"`
    );
    execSync(
        'git config --global merge.yarn-lock-driver.name "Custom merge driver for yarn.lock files"'
    );

    // Create or update .gitattributes in the repository root
    const repoRoot = execSync('git rev-parse --show-toplevel', {
        encoding: 'utf8',
    }).trim();
    const gitattributesPath = path.join(repoRoot, '.gitattributes');

    const attributes = `# Custom merge drivers for package.json and yarn.lock
package.json merge=package-json-driver
yarn.lock merge=yarn-lock-driver
`;

    // Append or update .gitattributes
    if (fs.existsSync(gitattributesPath)) {
        const content = fs.readFileSync(gitattributesPath, 'utf8');
        if (!content.includes('package.json merge=package-json-driver')) {
            fs.appendFileSync(gitattributesPath, '\n' + attributes);
        }
    } else {
        fs.writeFileSync(gitattributesPath, attributes);
    }

    console.log(
        'Successfully installed Git merge drivers for package.json and yarn.lock files.'
    );
    console.log(`Added configuration to ${gitattributesPath}`);
    console.log(
        "Don't forget to install required dependencies: npm install semver --save-dev"
    );
} catch (error) {
    console.error('Error installing Git merge drivers:', error);
    process.exit(1);
}
