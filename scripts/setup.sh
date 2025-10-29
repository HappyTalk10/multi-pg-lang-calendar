#!/bin/bash

# ========================================
# 環境セットアップスクリプト
# ========================================

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトの場所から自動的にプロジェクトルートを特定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Directory Check..."
echo "-----------------------------------"
echo "Script location: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo ""

cd "$PROJECT_ROOT"

# ディレクトリ確認
if [ ! -d "scripts" ]; then
    echo -e "${RED}❌ Error: scripts directory not found!${NC}"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo -e "${GREEN}✅ Working in: $(pwd)${NC}"
echo ""

# ========================================
# 言語環境チェック
# ========================================

echo "🔍 Checking language installations..."
echo "======================================"

# C言語
if command -v gcc &> /dev/null; then
    echo -e "${GREEN}✅ C (gcc)${NC}"
    gcc --version | head -n1 | sed 's/^/   /'
else
    echo -e "${RED}❌ C (gcc) not found${NC}"
fi

# Go
if command -v go &> /dev/null; then
    echo -e "${GREEN}✅ Go${NC}"
    go version | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠️  Go not found${NC}"
fi

# Kotlin
if command -v kotlin &> /dev/null; then
    echo -e "${GREEN}✅ Kotlin${NC}"
    kotlin -version 2>&1 | head -n1 | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠️  Kotlin not found - installing...${NC}"
    
    # SDKMAN のインストール
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
    
    # Kotlin のインストール
    sdk install kotlin < /dev/null
    echo -e "${GREEN}✅ Kotlin installed${NC}"
fi

# Rust
if command -v cargo &> /dev/null; then
    echo -e "${GREEN}✅ Rust${NC}"
    rustc --version | sed 's/^/   /'
    cargo --version | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠️  Rust not found - installing...${NC}"
    
    # Rust のインストール
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    
    echo -e "${GREEN}✅ Rust installed${NC}"
fi

echo ""

# ========================================
# シンボリックリンク作成
# ========================================

echo "🔗 Creating symbolic links for holiday data..."
echo "---------------------------------------------"

for dir in c go kotlin rust; do
    cd "$PROJECT_ROOT/$dir"
    if [ -f "../data/holidays.csv" ]; then
        ln -sf ../data/holidays.csv holidays.csv
        echo "✅ $dir/holidays.csv -> ../data/holidays.csv"
    else
        echo "⚠️  ../data/holidays.csv not found"
    fi
done

cd "$PROJECT_ROOT"
echo ""

# ========================================
# 言語別の初期化
# ========================================

echo "🔧 Language-specific initialization..."
echo "--------------------------------------"

# Go module
cd "$PROJECT_ROOT/go"
if [ ! -f "go.mod" ]; then
    go mod init calendar 2>/dev/null && echo "✅ Go module initialized"
fi
cd "$PROJECT_ROOT"

# Rust project
cd "$PROJECT_ROOT/rust"
if [ ! -f "Cargo.toml" ]; then
    cargo init --name calendar 2>/dev/null && echo "✅ Rust project initialized"
fi
cd "$PROJECT_ROOT"

echo ""
echo "✨ Setup complete!"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Add source code to each language directory"
echo "  2. Run: ./scripts/build-all.sh"
echo "  3. Run: ./scripts/test-all.sh"
