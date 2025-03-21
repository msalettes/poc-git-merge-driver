#!/usr/bin/env node

const fs = require('fs');

const semver = require('semver');

// Get file paths from Git merge driver arguments
const [ancestorPath, currentPath, otherPath, marker] = process.argv.slice(2);

function mergeDependencies(ancestor, current, other) {
    const result = { ...current };

    // Process each dependency in the 'other' branch
    for (const [pkg, otherVersion] of Object.entries(other)) {
        // If current doesn't have this package, just add it
        if (!result[pkg]) {
            result[pkg] = otherVersion;
            continue;
        }

        // If the versions are the same, no conflict
        if (result[pkg] === otherVersion) {
            continue;
        }

        // Check if it's a @mirakl package or has semver versions
        if (
            pkg.startsWith('@mirakl/') ||
            (semver.valid(semver.coerce(result[pkg])) &&
                semver.valid(semver.coerce(otherVersion)))
        ) {
            // Choose the higher version
            const currentSemver = semver.coerce(result[pkg]);
            const otherSemver = semver.coerce(otherVersion);

            if (semver.gt(otherSemver, currentSemver)) {
                result[pkg] = otherVersion;
            }
        }
        // For non-semver or non-mirakl packages with conflicts, keep current version
        // You could expand this logic for other special cases
    }

    return result;
}

try {
    // Parse the JSON files
    const ancestorContent = JSON.parse(fs.readFileSync(ancestorPath, 'utf8'));
    const currentContent = JSON.parse(fs.readFileSync(currentPath, 'utf8'));
    const otherContent = JSON.parse(fs.readFileSync(otherPath, 'utf8'));

    // Helper function to merge dependency sections
    // Create merged package.json
    const mergedContent = { ...currentContent };

    // Merge each dependency section
    for (const section of [
        'dependencies',
        'devDependencies',
        'peerDependencies',
        'optionalDependencies',
    ]) {
        if (otherContent[section] && currentContent[section]) {
            mergedContent[section] = mergeDependencies(
                ancestorContent[section] || {},
                currentContent[section] || {},
                otherContent[section] || {}
            );
        } else if (otherContent[section]) {
            mergedContent[section] = otherContent[section];
        }
    }

    // Write the merged content back to the current file
    fs.writeFileSync(
        currentPath,
        JSON.stringify(mergedContent, null, 2) + '\n'
    );
    process.exit(0); // Success
} catch (error) {
    console.error('Error merging package.json:', error);
    process.exit(1); // Failure, let Git handle it
}
