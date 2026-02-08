#!/bin/bash
set -e

# Usage: ./bump-version.sh <new_version>
# Example: ./bump-version.sh 1.3.0

NEW_VERSION=$1

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <new_version>"
    echo "Example: $0 1.3.0"
    exit 1
fi

echo "Bumping version to $NEW_VERSION..."

# Update HealthQL.podspec
sed -i '' "s/s.version          = '[^']*'/s.version          = '$NEW_VERSION'/" HealthQL.podspec
echo "Updated HealthQL.podspec"

# Update package.json
sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" packages/react-native-healthql/package.json
echo "Updated packages/react-native-healthql/package.json"

echo "Version bump complete: $NEW_VERSION"
