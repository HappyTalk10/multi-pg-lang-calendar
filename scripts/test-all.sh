#!/bin/bash

# カラー定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🧪 Testing all languages..."
echo "Working directory: $(pwd)"
echo "======================================"
echo ""

TEST_INPUT="2025
5"

# C言語
if [ -f "c/calendar" ]; then
    echo -e "${BLUE}Testing C...${NC}"
    echo "-----------------------------------"
    cd "$PROJECT_ROOT/c"
    pwd
    echo "$TEST_INPUT" | ./calendar | head -n 30
    echo -e "${GREEN}✅ C test complete${NC}"
    cd "$PROJECT_ROOT"
else
    echo -e "${RED}❌ C binary not found. Run build-all.sh first.${NC}"
fi
echo ""

# Go
if [ -f "go/calendar" ]; then
    echo -e "${BLUE}Testing Go...${NC}"
    echo "-----------------------------------"
    cd "$PROJECT_ROOT/go"
    pwd
    echo "$TEST_INPUT" | ./calendar | head -n 30
    echo -e "${GREEN}✅ Go test complete${NC}"
    cd "$PROJECT_ROOT"
else
    echo -e "${RED}❌ Go binary not found. Run build-all.sh first.${NC}"
fi
echo ""

# Kotlin
if [ -f "kotlin/calendar.jar" ]; then
    echo -e "${BLUE}Testing Kotlin...${NC}"
    echo "-----------------------------------"
    cd "$PROJECT_ROOT/kotlin"
    pwd
    echo "$TEST_INPUT" | java -jar calendar.jar | head -n 30
    echo -e "${GREEN}✅ Kotlin test complete${NC}"
    cd "$PROJECT_ROOT"
else
    echo -e "${RED}❌ Kotlin JAR not found. Run build-all.sh first.${NC}"
fi
echo ""

# Rust
if [ -f "rust/target/release/calendar" ]; then
    echo -e "${BLUE}Testing Rust...${NC}"
    echo "-----------------------------------"
    cd "$PROJECT_ROOT/rust"
    pwd
    echo "$TEST_INPUT" | ./target/release/calendar | head -n 30
    echo -e "${GREEN}✅ Rust test complete${NC}"
    cd "$PROJECT_ROOT"
else
    echo -e "${RED}❌ Rust binary not found. Run build-all.sh first.${NC}"
fi
echo ""

cd "$PROJECT_ROOT"
echo "======================================"
echo "✅ All tests complete!"
echo "Current directory: $(pwd)"
