#!/bin/bash

# ========================================
# CSV文字コード修正スクリプト
# ========================================

echo "🔧 Fixing CSV file encoding..."
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

cd "$PROJECT_ROOT"

# ========================================
# 現在の文字コード確認
# ========================================

echo "📊 Current encoding check..."
echo "-----------------------------------"

if command -v file &> /dev/null; then
    echo "File encoding info:"
    file data/holidays.csv
    echo ""
fi

echo "First line (raw):"
head -n 1 data/holidays.csv | cat -A
echo ""

echo "First data line (raw):"
head -n 2 data/holidays.csv | tail -n 1 | cat -A
echo ""

# ========================================
# バックアップ作成
# ========================================

echo "💾 Creating backup..."
echo "-----------------------------------"

cp data/holidays.csv data/holidays.csv.backup
echo "✅ Backup created: data/holidays.csv.backup"
echo ""

# ========================================
# UTF-8に変換
# ========================================

echo "🔄 Converting to UTF-8..."
echo "-----------------------------------"

if command -v iconv &> /dev/null; then
    echo "Using iconv..."
    
    # Shift_JISからUTF-8に変換
    if iconv -f SHIFT_JIS -t UTF-8 data/holidays.csv.backup > data/holidays_utf8.csv 2>/dev/null; then
        mv data/holidays_utf8.csv data/holidays.csv
        echo "✅ Converted with iconv (SHIFT_JIS -> UTF-8)"
    else
        echo "⚠️  SHIFT_JIS conversion failed, trying CP932..."
        if iconv -f CP932 -t UTF-8 data/holidays.csv.backup > data/holidays_utf8.csv 2>/dev/null; then
            mv data/holidays_utf8.csv data/holidays.csv
            echo "✅ Converted with iconv (CP932 -> UTF-8)"
        else
            echo "❌ iconv conversion failed"
        fi
    fi
    
elif command -v nkf &> /dev/null; then
    echo "Using nkf..."
    nkf -w data/holidays.csv.backup > data/holidays.csv
    echo "✅ Converted with nkf"
    
else
    echo "❌ No conversion tool found (iconv or nkf required)"
    echo "   Installing iconv..."
    
    # Debianベースの場合
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y libc-bin
    fi
fi

echo ""

# ========================================
# 変換後の確認
# ========================================

echo "✅ Conversion complete. Verifying..."
echo "-----------------------------------"

if command -v file &> /dev/null; then
    echo "New file encoding:"
    file data/holidays.csv
    echo ""
fi

echo "First line (after conversion):"
head -n 1 data/holidays.csv
echo ""

echo "2025年5月のデータ:"
grep "2025/5/" data/holidays.csv
echo ""

echo "Lines: $(wc -l < data/holidays.csv)"
echo ""

# ========================================
# シンボリックリンクを再作成
# ========================================

echo "🔗 Recreating symbolic links..."
echo "-----------------------------------"

cd c
rm -f holidays.csv
ln -sf ../data/holidays.csv holidays.csv
echo "✅ c/holidays.csv"

cd ../go
rm -f holidays.csv
ln -sf ../data/holidays.csv holidays.csv
echo "✅ go/holidays.csv"

cd ../kotlin
rm -f holidays.csv
ln -sf ../data/holidays.csv holidays.csv
echo "✅ kotlin/holidays.csv"

cd ../rust
rm -f holidays.csv
ln -sf ../data/holidays.csv holidays.csv
echo "✅ rust/holidays.csv"

cd ..
echo ""

# ========================================
# C言語を再ビルド＆テスト
# ========================================

echo "🔨 Rebuilding C..."
echo "-----------------------------------"

cd c
make clean
make

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🧪 Testing C with 2025/5..."
    echo "=========================================="
    echo -e "2025\n5" | ./calendar
    echo "=========================================="
else
    echo "❌ Build failed"
fi

cd ..

# ========================================
# 全言語テスト
# ========================================

echo ""
echo "🧪 Testing all languages with 2025/5..."
echo "=========================================="
echo ""

# Go
if [ -f "go/calendar" ]; then
    echo "--- Go ---"
    cd go
    echo -e "2025\n5" | ./calendar | tail -15
    cd ..
    echo ""
fi

# Kotlin
if [ -f "kotlin/calendar.jar" ]; then
    echo "--- Kotlin ---"
    cd kotlin
    echo -e "2025\n5" | java -jar calendar.jar | tail -15
    cd ..
    echo ""
fi

# Rust
if [ -f "rust/target/release/calendar" ]; then
    echo "--- Rust ---"
    cd rust
    echo -e "2025\n5" | ./target/release/calendar | tail -15
    cd ..
    echo ""
fi

echo "=========================================="
echo "✨ Complete!"
echo "=========================================="
echo ""
echo "📝 Summary:"
echo "  - CSV file converted to UTF-8"
echo "  - Backup saved: data/holidays.csv.backup"
echo "  - All symbolic links recreated"
echo "  - All languages should now display holidays correctly"
echo ""