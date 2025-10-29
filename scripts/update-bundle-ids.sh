#!/bin/bash

# Script to update Bundle IDs and Team ID across the project
# Usage: ./scripts/update-bundle-ids.sh NEW_BUNDLE_PREFIX NEW_TEAM_ID
#
# Example: ./scripts/update-bundle-ids.sh com.vibecoding.bloomly YOUR_TEAM_ID

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Invalid number of arguments${NC}"
    echo "Usage: $0 NEW_BUNDLE_PREFIX NEW_TEAM_ID"
    echo ""
    echo "Example: $0 com.vibecoding.bloomly ABC123XYZ"
    exit 1
fi

NEW_BUNDLE_PREFIX=$1
NEW_TEAM_ID=$2

# Extract base name (last component)
BASE_NAME=$(echo "$NEW_BUNDLE_PREFIX" | awk -F. '{print $NF}')

echo -e "${GREEN}=== BabyTrack Bundle ID Update Script ===${NC}"
echo ""
echo "Old Bundle Prefix: com.example"
echo "New Bundle Prefix: $NEW_BUNDLE_PREFIX"
echo ""
echo "Old Team ID: ABCDE12345"
echo "New Team ID: $NEW_TEAM_ID"
echo ""
echo "This will update:"
echo "  - Project.swift"
echo "  - All entitlements files"
echo "  - ProductIDs.swift"
echo "  - Configuration.storekit"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo -e "${YELLOW}Backing up files...${NC}"
mkdir -p backups
cp Project.swift backups/Project.swift.bak
cp App/Resources/BabyTrack.entitlements backups/BabyTrack.entitlements.bak
cp Packages/Paywall/Sources/Paywall/Domain/ProductIDs.swift backups/ProductIDs.swift.bak
cp Configuration.storekit backups/Configuration.storekit.bak
echo -e "${GREEN}✓ Backups created in ./backups/${NC}"

echo -e "${YELLOW}Updating Project.swift...${NC}"
sed -i.tmp "s/let bundlePrefix = \"com.example\"/let bundlePrefix = \"$(echo $NEW_BUNDLE_PREFIX | sed 's/\.[^.]*$//')\"/" Project.swift
sed -i.tmp "s/let teamID = \"ABCDE12345\"/let teamID = \"$NEW_TEAM_ID\"/" Project.swift
rm Project.swift.tmp
echo -e "${GREEN}✓ Updated Project.swift${NC}"

echo -e "${YELLOW}Updating entitlements files...${NC}"

# App entitlements
sed -i.tmp "s/iCloud.com.example.BabyTrack/iCloud.$NEW_BUNDLE_PREFIX/" App/Resources/BabyTrack.entitlements
sed -i.tmp "s/group.com.example.babytrack/group.$NEW_BUNDLE_PREFIX/" App/Resources/BabyTrack.entitlements
rm App/Resources/BabyTrack.entitlements.tmp
echo -e "${GREEN}✓ Updated App/Resources/BabyTrack.entitlements${NC}"

# Widget entitlements
if [ -f Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements ]; then
    sed -i.tmp "s/iCloud.com.example.BabyTrack/iCloud.$NEW_BUNDLE_PREFIX/" Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements
    sed -i.tmp "s/group.com.example.babytrack/group.$NEW_BUNDLE_PREFIX/" Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements
    rm Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements.tmp
    echo -e "${GREEN}✓ Updated Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements${NC}"
fi

# Watch entitlements
if [ -f Targets/BabyTrackWatchExtension/BabyTrackWatchExtension.entitlements ]; then
    sed -i.tmp "s/iCloud.com.example.BabyTrack/iCloud.$NEW_BUNDLE_PREFIX/" Targets/BabyTrackWatchExtension/BabyTrackWatchExtension.entitlements
    sed -i.tmp "s/group.com.example.babytrack/group.$NEW_BUNDLE_PREFIX/" Targets/BabyTrackWatchExtension/BabyTrackWatchExtension.entitlements
    rm Targets/BabyTrackWatchExtension/BabyTrackWatchExtension.entitlements.tmp
    echo -e "${GREEN}✓ Updated Targets/BabyTrackWatchExtension/BabyTrackWatchExtension.entitlements${NC}"
fi

echo -e "${YELLOW}Updating ProductIDs.swift...${NC}"
sed -i.tmp "s/com.example.babytrack/$NEW_BUNDLE_PREFIX/g" Packages/Paywall/Sources/Paywall/Domain/ProductIDs.swift
rm Packages/Paywall/Sources/Paywall/Domain/ProductIDs.swift.tmp
echo -e "${GREEN}✓ Updated Packages/Paywall/Sources/Paywall/Domain/ProductIDs.swift${NC}"

echo -e "${YELLOW}Updating Configuration.storekit...${NC}"
sed -i.tmp "s/com.example.babytrack/$NEW_BUNDLE_PREFIX/g" Configuration.storekit
sed -i.tmp "s/\"ABCDE12345\"/\"$NEW_TEAM_ID\"/" Configuration.storekit
rm Configuration.storekit.tmp
echo -e "${GREEN}✓ Updated Configuration.storekit${NC}"

echo ""
echo -e "${GREEN}=== Update Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Run 'tuist generate' to regenerate the Xcode project"
echo "2. Open BabyTrack.xcworkspace in Xcode"
echo "3. Verify Bundle IDs in project settings"
echo "4. Update provisioning profiles in Xcode"
echo ""
echo "New Bundle IDs:"
echo "  - Main App: $NEW_BUNDLE_PREFIX"
echo "  - Widgets:  $NEW_BUNDLE_PREFIX.widgets"
echo "  - Watch:    $NEW_BUNDLE_PREFIX.watchapp"
echo "  - Watch Ext: $NEW_BUNDLE_PREFIX.watchkitextension"
echo ""
echo "iCloud Container: iCloud.$NEW_BUNDLE_PREFIX"
echo "App Group: group.$NEW_BUNDLE_PREFIX"
echo ""
echo -e "${YELLOW}Don't forget to create these in Apple Developer Portal!${NC}"
