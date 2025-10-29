#!/bin/bash

# カラー定義
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🔨 Building all languages..."
echo "Working directory: $(pwd)"
echo "======================================"
echo ""

# C言語
echo -e "${BLUE}📦 Building C...${NC}"
echo "-----------------------------------"
cd "$PROJECT_ROOT/c"
pwd
if [ -f "calendar.c" ]; then
    if make clean && make; then
        echo -e "${GREEN}✅ C build successful${NC}"
        ls -lh calendar
    else
        echo -e "${RED}❌ C build failed${NC}"
    fi
else
    echo -e "${RED}❌ calendar.c not found${NC}"
fi
echo ""

# Go
echo -e "${BLUE}📦 Building Go...${NC}"
echo "-----------------------------------"
cd "$PROJECT_ROOT/go"
pwd
if [ -f "calendar.go" ]; then
    if go build -o calendar calendar.go; then
        echo -e "${GREEN}✅ Go build successful${NC}"
        ls -lh calendar
    else
        echo -e "${RED}❌ Go build failed${NC}"
    fi
else
    echo -e "${RED}❌ calendar.go not found${NC}"
fi
echo ""

# Kotlin
echo -e "${BLUE}📦 Building Kotlin...${NC}"
echo "-----------------------------------"
cd "$PROJECT_ROOT/kotlin"
pwd
if [ -f "calendar.kt" ]; then
    if kotlinc calendar.kt -include-runtime -d calendar.jar; then
        echo -e "${GREEN}✅ Kotlin build successful${NC}"
        ls -lh calendar.jar
    else
        echo -e "${RED}❌ Kotlin build failed${NC}"
    fi
else
    echo -e "${RED}❌ calendar.kt not found${NC}"
fi
echo ""

# Rust
echo -e "${BLUE}📦 Building Rust...${NC}"
echo "-----------------------------------"
cd "$PROJECT_ROOT/rust"
pwd
if [ -f "src/main.rs" ]; then
    if cargo build --release; then
        echo -e "${GREEN}✅ Rust build successful${NC}"
        ls -lh target/release/calendar
    else
        echo -e "${RED}❌ Rust build failed${NC}"
    fi
else
    echo -e "${RED}❌ src/main.rs not found${NC}"
fi
echo ""

cd "$PROJECT_ROOT"
echo "======================================"
echo "✨ Build process complete!"
echo "Current directory: $(pwd)"
