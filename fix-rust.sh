#!/bin/bash

# ========================================
# Rust依存関係修正スクリプト
# ========================================

echo "🔧 Fixing Rust dependencies..."
echo "=========================================="
echo ""

# プロジェクトルート検出
if [ -d "/workspaces/multi-pg-lang-calendar" ]; then
    PROJECT_ROOT="/workspaces/multi-pg-lang-calendar"
elif [ -d "$HOME/multi-pg-lang-calendar" ]; then
    PROJECT_ROOT="$HOME/multi-pg-lang-calendar"
else
    echo "❌ プロジェクトディレクトリが見つかりません"
    exit 1
fi

cd "$PROJECT_ROOT/rust"
echo "Working in: $(pwd)"
echo ""

# ========================================
# Cargo.toml を修正
# ========================================

echo "📝 Updating Cargo.toml..."
echo "-----------------------------------"

cat > Cargo.toml << 'TOML_EOF'
[package]
name = "calendar"
version = "0.1.0"
edition = "2021"

[dependencies]
reqwest = { version = "0.11", features = ["blocking"] }
encoding_rs = "0.8"
TOML_EOF

echo "✅ Cargo.toml updated"
echo ""

# ========================================
# 依存関係を追加
# ========================================

echo "📦 Adding dependencies..."
echo "-----------------------------------"

# 環境変数を読み込み
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

cargo add reqwest --features blocking
cargo add encoding_rs

echo ""
echo "✅ Dependencies added"
echo ""

# ========================================
# クリーンビルド
# ========================================

echo "🔨 Clean build..."
echo "-----------------------------------"

cargo clean
cargo build --release

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Rust build successful!"
    echo "=========================================="
    echo ""
    echo "📊 Binary info:"
    ls -lh target/release/calendar
    echo ""
    echo "📝 Test it:"
    echo "   cd $PROJECT_ROOT/rust"
    echo "   echo -e '2025\n5' | ./target/release/calendar"
else
    echo ""
    echo "=========================================="
    echo "❌ Build failed"
    echo "=========================================="
fi

echo ""
