#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up test environment...${NC}"

# Create test directory
TEST_DIR="$(mktemp -d)"
cd "$TEST_DIR"
echo "Working in temporary directory: $TEST_DIR"

# Initialize git
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Install the semver dependency for the merge drivers
npm init -y > /dev/null
npm install semver > /dev/null

# Copy merge drivers to the test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/package-json-merge-driver.js" ./
cp "$SCRIPT_DIR/yarn-lock-merge-driver.js" ./
chmod +x package-json-merge-driver.js yarn-lock-merge-driver.js

# Configure git to use the local merge drivers
git config merge.package-json-driver.driver "$TEST_DIR/package-json-merge-driver.js %O %A %B %P"
git config merge.package-json-driver.name "Package.json merge driver"
git config merge.yarn-lock-driver.driver "$TEST_DIR/yarn-lock-merge-driver.js %O %A %B %P"
git config merge.yarn-lock-driver.name "Yarn.lock merge driver"

# Create .gitattributes
cat > .gitattributes << EOF
package.json merge=package-json-driver
yarn.lock merge=yarn-lock-driver
EOF

git add .gitattributes
git commit -m "Add .gitattributes" > /dev/null

# Create initial package.json
cat > package.json << EOF
{
  "name": "merge-driver-test",
  "version": "1.0.0",
  "dependencies": {
    "@mirakl/core": "1.0.0",
    "react": "17.0.2"
  }
}
EOF

# Initialize yarn and create lock file
yarn install > /dev/null
git add package.json yarn.lock
git commit -m "Initial commit with dependencies" > /dev/null

echo -e "${GREEN}Setup complete. Beginning tests...${NC}"

# Test 1: Simple version bump conflict
echo -e "${GREEN}Test 1: Simple version bump conflict${NC}"
git checkout -b feature-a > /dev/null

# Update package in feature-a
cat > package.json << EOF
{
  "name": "merge-driver-test",
  "version": "1.0.0",
  "dependencies": {
    "@mirakl/core": "1.1.0",
    "react": "17.0.2"
  }
}
EOF
yarn install > /dev/null
git add package.json yarn.lock
git commit -m "Upgrade @mirakl/core to 1.1.0" > /dev/null

# Go back to master and create feature-b
git checkout master > /dev/null
git checkout -b feature-b > /dev/null

# Update package in feature-b with higher version
cat > package.json << EOF
{
  "name": "merge-driver-test",
  "version": "1.0.0",
  "dependencies": {
    "@mirakl/core": "1.2.0",
    "react": "17.0.2",
    "@mirakl/sdk": "2.0.0"
  }
}
EOF
yarn install > /dev/null
git add package.json yarn.lock
git commit -m "Upgrade @mirakl/core to 1.2.0 and add @mirakl/sdk" > /dev/null

# Merge feature-b into feature-a
git checkout feature-a > /dev/null
git merge feature-b > /dev/null 2>&1 || echo "Merge conflict occurred (expected)"

# Check results
CORE_VERSION=$(grep -o '"@mirakl/core": "[^"]*"' package.json | cut -d'"' -f4)
if [ "$CORE_VERSION" = "1.2.0" ]; then
  echo -e "${GREEN}✓ @mirakl/core version is correctly set to higher version (1.2.0)${NC}"
else
  echo -e "${RED}✗ @mirakl/core version is not correctly set. Found: $CORE_VERSION${NC}"
fi

if grep -q "@mirakl/sdk" package.json; then
  echo -e "${GREEN}✓ New package @mirakl/sdk was correctly added${NC}"
else
  echo -e "${RED}✗ New package @mirakl/sdk was not added${NC}"
fi

# Test yarn.lock integrity
if yarn check --integrity > /dev/null 2>&1; then
  echo -e "${GREEN}✓ yarn.lock is consistent with package.json${NC}"
else
  echo -e "${RED}✗ yarn.lock is not consistent with package.json${NC}"
fi

# Test 2: Conflict in the same line
echo -e "\n${GREEN}Test 2: Conflict in the same line${NC}"

git checkout master > /dev/null
git checkout -b branch-1 > /dev/null

cat > package.json << EOF
{
  "name": "merge-driver-test",
  "version": "1.0.0",
  "dependencies": {
    "@mirakl/front": "3.1.0",
    "@mirakl/core": "1.0.0",
    "react": "17.0.2"
  }
}
EOF
yarn install > /dev/null
git add package.json yarn.lock
git commit -m "Add @mirakl/front 3.1.0" > /dev/null

git checkout master > /dev/null
git checkout -b branch-2 > /dev/null

cat > package.json << EOF
{
  "name": "merge-driver-test",
  "version": "1.0.0",
  "dependencies": {
    "@mirakl/front": "3.2.0",
    "@mirakl/core": "1.0.0",
    "react": "17.0.2"
  }
}
EOF
yarn install > /dev/null
git add package.json yarn.lock
git commit -m "Add @mirakl/front 3.2.0" > /dev/null

git checkout branch-1 > /dev/null
git merge branch-2 > /dev/null 2>&1 || echo "Merge conflict occurred (expected)"

FRONT_VERSION=$(grep -o '"@mirakl/front": "[^"]*"' package.json | cut -d'"' -f4)
if [ "$FRONT_VERSION" = "3.2.0" ]; then
  echo -e "${GREEN}✓ @mirakl/front version is correctly set to higher version (3.2.0)${NC}"
else
  echo -e "${RED}✗ @mirakl/front version is not correctly set. Found: $FRONT_VERSION${NC}"
fi

# Check yarn.lock integrity again
if yarn check --integrity > /dev/null 2>&1; then
  echo -e "${GREEN}✓ yarn.lock is consistent with package.json${NC}"
else
  echo -e "${RED}✗ yarn.lock is not consistent with package.json${NC}"
fi

echo -e "\n${GREEN}Tests completed. Test directory: $TEST_DIR${NC}"
echo -e "${GREEN}You can examine the results manually or delete the directory when done.${NC}"
