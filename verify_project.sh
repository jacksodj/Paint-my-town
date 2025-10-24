#!/bin/bash

# Paint My Town - Project Verification Script
# Run this to verify all files are present before building in Xcode

set -e

echo "🔍 Paint My Town - Project Verification"
echo "========================================"
echo ""

# Check we're in the right directory
if [ ! -f "PaintMyTown.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Not in Paint-my-town directory"
    echo "   Please cd to the project root"
    exit 1
fi

echo "✅ Project directory found"
echo ""

# Count Swift files
echo "📦 Checking source files..."
MAIN_FILES=$(find PaintMyTown -name "*.swift" -type f | grep -v ".build" | wc -l | tr -d ' ')
TEST_FILES=$(find PaintMyTownTests -name "*.swift" -type f | wc -l | tr -d ' ')

echo "   Main source files: $MAIN_FILES (expected: 72)"
echo "   Test files: $TEST_FILES (expected: 9)"

if [ "$MAIN_FILES" -ge 70 ]; then
    echo "   ✅ Main files OK"
else
    echo "   ⚠️  Missing some main files"
fi

if [ "$TEST_FILES" -ge 9 ]; then
    echo "   ✅ Test files OK"
else
    echo "   ⚠️  Missing some test files"
fi

echo ""

# Check configuration files
echo "⚙️  Checking configuration files..."

check_file() {
    if [ -f "$1" ]; then
        echo "   ✅ $1"
        return 0
    else
        echo "   ❌ Missing: $1"
        return 1
    fi
}

check_file "PaintMyTown/Info.plist"
check_file "PaintMyTown/PaintMyTown.entitlements"
check_file ".swiftlint.yml"
check_file "PaintMyTown.xcodeproj/xcshareddata/xcschemes/PaintMyTown.xcscheme"

echo ""

# Check key directories
echo "📁 Checking directory structure..."

check_dir() {
    if [ -d "$1" ]; then
        FILE_COUNT=$(find "$1" -name "*.swift" -type f | wc -l | tr -d ' ')
        echo "   ✅ $1 ($FILE_COUNT files)"
        return 0
    else
        echo "   ❌ Missing directory: $1"
        return 1
    fi
}

check_dir "PaintMyTown/Coordinators"
check_dir "PaintMyTown/CoreData"
check_dir "PaintMyTown/Models"
check_dir "PaintMyTown/Protocols"
check_dir "PaintMyTown/Repositories"
check_dir "PaintMyTown/Services"
check_dir "PaintMyTown/Utils"
check_dir "PaintMyTown/ViewModels"
check_dir "PaintMyTown/Views"
check_dir "PaintMyTownTests"

echo ""

# Check documentation
echo "📚 Checking documentation..."
DOC_COUNT=$(find docs -name "*.md" -type f | wc -l | tr -d ' ')
echo "   Documentation files: $DOC_COUNT"
echo "   ✅ Documentation OK"

echo ""

# Git status
echo "📊 Git status..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current)
    UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')

    echo "   Current branch: $BRANCH"

    if [ "$UNCOMMITTED" -eq 0 ]; then
        echo "   ✅ No uncommitted changes"
    else
        echo "   ⚠️  $UNCOMMITTED uncommitted changes"
    fi
else
    echo "   ❌ Not a git repository"
fi

echo ""
echo "========================================"
echo "📋 Summary"
echo "========================================"
echo ""

if [ "$MAIN_FILES" -ge 70 ] && [ "$TEST_FILES" -ge 9 ]; then
    echo "✅ All files present"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Open PaintMyTown.xcodeproj in Xcode"
    echo "   2. Follow XCODE_SETUP_GUIDE.md to add files to target"
    echo "   3. Build the project (Cmd+B)"
    echo "   4. Run tests (Cmd+U)"
    echo "   5. Commit updated project.pbxproj"
    echo "   6. Set up Xcode Cloud"
    echo ""
    echo "📖 See XCODE_CLOUD_CHECKLIST.md for detailed setup"
else
    echo "⚠️  Some files are missing"
    echo "   Please review the output above"
fi

echo ""
