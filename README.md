# 🗓️ Multi-PG-Lang Calendar
## 複数プログラミング言語で実装したカレンダーアプリ

> Calendar App implemented in C, Go, Kotlin & Rust  
> C言語、Go、Kotlin、Rustで実装した祝日対応カレンダー

## ✨ Features / 特徴

- 🌐 4つのプログラミング言語で同じ機能を実装
- 📥 内閣府の祝日データ自動取得 (Go/Kotlin/Rust)
- 🚀 GitHub Codespaces で即座に試せる
- 📊 言語間のベンチマーク比較
- 🔄 クロスコンパイル対応 (Go)

## 🚀 Quick Start

### 1. Setup (初回のみ)
```bash
./scripts/setup.sh
```

### 2. Build All
```bash
./scripts/build-all.sh
```

### 3. Test All
```bash
./scripts/test-all.sh
```

## 📁 Directory Structure
```
multi-pg-lang-calendar/
├── c/              # C言語実装
├── go/             # Go実装
├── kotlin/         # Kotlin実装
├── rust/           # Rust実装
├── data/           # 共通データ（祝日CSV）
├── scripts/        # ビルド・テストスクリプト
└── docs/           # ドキュメント
```

## 🎯 Individual Usage

### C
```bash
cd c
make
./calendar
```

### Go
```bash
cd go
go run calendar.go
```

### Kotlin
```bash
cd kotlin
kotlin calendar.kt
```

### Rust
```bash
cd rust
cargo run
```

## 📄 License

MIT License
