#!/bin/bash

# ========================================
# C言語祝日表示修正スクリプト
# ========================================

echo "🔧 Fixing C language holiday display issue..."
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
echo "Working in: $(pwd)"
echo ""

# ========================================
# デバッグ用：CSVファイルの内容確認
# ========================================

echo "📊 Checking CSV file content..."
echo "-----------------------------------"

if [ -f "data/holidays.csv" ]; then
    echo "Searching for 2025年5月 holidays:"
    grep "2025" data/holidays.csv | grep -E "(05-|/5/)" | head -5
    echo ""
    
    echo "First data line format:"
    head -n 2 data/holidays.csv | tail -n 1
    echo ""
fi

# ========================================
# C言語コード修正（デバッグ出力追加版）
# ========================================

echo "📝 Creating fixed C code with debug output..."
echo "-----------------------------------"

cat > c/calendar.c << 'C_SOURCE_EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_HOLIDAYS 600
#define DEBUG 0  // デバッグモード: 1で有効化

typedef struct {
    int year;
    int month;
    int day;
    char name[100];
} Holiday;

Holiday holidays[MAX_HOLIDAYS];
int holiday_count = 0;

const char* weekdays[] = {"日", "月", "火", "水", "木", "金", "土"};

int load_holidays_from_file(const char* filename) {
    FILE *fp = fopen(filename, "r");
    if (fp == NULL) {
        printf("エラー: ファイル '%s' が開けません。\n", filename);
        return 0;
    }

    char line[512];
    int line_num = 0;
    
    // ヘッダー行をスキップ
    if (fgets(line, sizeof(line), fp) != NULL) {
        line_num++;
        if (DEBUG) printf("Header: %s", line);
    }

    while (fgets(line, sizeof(line), fp) != NULL && holiday_count < MAX_HOLIDAYS) {
        line_num++;
        
        // 改行文字を削除
        line[strcspn(line, "\n")] = 0;
        line[strcspn(line, "\r")] = 0;
        
        // 空行をスキップ
        if (strlen(line) == 0) continue;

        char date_str[20] = "";
        char name[100] = "";
        
        // カンマで分割
        char *comma = strchr(line, ',');
        if (comma == NULL) {
            if (DEBUG) printf("Line %d: No comma found\n", line_num);
            continue;
        }
        
        int date_len = comma - line;
        if (date_len >= sizeof(date_str)) {
            if (DEBUG) printf("Line %d: Date too long\n", line_num);
            continue;
        }
        
        strncpy(date_str, line, date_len);
        date_str[date_len] = '\0';
        
        // 名前部分をコピー（先頭の空白を削除）
        char *name_start = comma + 1;
        while (*name_start == ' ') name_start++;
        strncpy(name, name_start, sizeof(name) - 1);
        name[sizeof(name) - 1] = '\0';
        
        // 日付をパース（ハイフンとスラッシュ両方対応）
        int year = 0, month = 0, day = 0;
        int parsed = 0;
        
        // ハイフン区切りを試す
        if (sscanf(date_str, "%d-%d-%d", &year, &month, &day) == 3) {
            parsed = 1;
        }
        // スラッシュ区切りを試す
        else if (sscanf(date_str, "%d/%d/%d", &year, &month, &day) == 3) {
            parsed = 1;
        }
        
        if (parsed && year >= 1900 && year <= 2100 && 
            month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            
            holidays[holiday_count].year = year;
            holidays[holiday_count].month = month;
            holidays[holiday_count].day = day;
            strncpy(holidays[holiday_count].name, name, sizeof(holidays[holiday_count].name) - 1);
            holidays[holiday_count].name[sizeof(holidays[holiday_count].name) - 1] = '\0';
            
            if (DEBUG && year == 2025 && month == 5) {
                printf("Loaded: %d/%d/%d = %s\n", year, month, day, name);
            }
            
            holiday_count++;
        } else {
            if (DEBUG) printf("Line %d: Failed to parse or invalid date: %s\n", line_num, date_str);
        }
    }

    fclose(fp);
    printf("祝日データを読み込みました: %d件\n", holiday_count);
    
    if (DEBUG) {
        printf("\nDebug: 2025年5月の祝日:\n");
        for (int i = 0; i < holiday_count; i++) {
            if (holidays[i].year == 2025 && holidays[i].month == 5) {
                printf("  %d日: %s\n", holidays[i].day, holidays[i].name);
            }
        }
    }
    
    return 1;
}

int is_holiday(int year, int month, int day, char* holiday_name) {
    for (int i = 0; i < holiday_count; i++) {
        if (holidays[i].year == year && 
            holidays[i].month == month && 
            holidays[i].day == day) {
            if (holiday_name != NULL) {
                strcpy(holiday_name, holidays[i].name);
            }
            return 1;
        }
    }
    return 0;
}

int get_days_in_month(int year, int month) {
    int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month == 2) {
        if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
            return 29;
        }
    }
    return days[month - 1];
}

int get_weekday(int year, int month, int day) {
    if (month < 3) {
        year--;
        month += 12;
    }
    int h = (day + (13 * (month + 1)) / 5 + year + year / 4 - year / 100 + year / 400) % 7;
    return (h + 6) % 7;
}

void print_calendar(int year, int month) {
    printf("\n        %d年 %d月\n", year, month);
    printf("----------------------------\n");
    
    for (int i = 0; i < 7; i++) {
        printf(" %s ", weekdays[i]);
    }
    printf("\n");
    printf("----------------------------\n");
    
    int first_day = get_weekday(year, month, 1);
    int days_in_month = get_days_in_month(year, month);
    
    // 月初めまでの空白
    for (int i = 0; i < first_day; i++) {
        printf("    ");
    }
    
    int current_weekday = first_day;
    for (int day = 1; day <= days_in_month; day++) {
        int is_hol = is_holiday(year, month, day, NULL);
        
        if (is_hol) {
            printf("%3d*", day);
        } else {
            printf("%3d ", day);
        }
        
        current_weekday++;
        if (current_weekday == 7) {
            printf("\n");
            current_weekday = 0;
        }
    }
    
    if (current_weekday != 0) {
        printf("\n");
    }
    printf("----------------------------\n");
    
    // 祝日リスト表示
    printf("\n【祝日】\n");
    int found = 0;
    for (int i = 0; i < holiday_count; i++) {
        if (holidays[i].year == year && holidays[i].month == month) {
            printf("  %2d日: %s\n", holidays[i].day, holidays[i].name);
            found = 1;
        }
    }
    if (!found) {
        printf("  なし\n");
    }
    printf("\n");
}

int main() {
    int year, month;
    
    printf("=== 月間カレンダー（祝日対応版）C言語 ===\n\n");
    
    // 複数のパスを試す
    const char* filenames[] = {
        "holidays.csv",
        "../data/holidays.csv",
        "data/holidays.csv"
    };
    
    int loaded = 0;
    for (int i = 0; i < 3 && !loaded; i++) {
        if (DEBUG) printf("Trying to load: %s\n", filenames[i]);
        else printf("Trying to load: %s\n", filenames[i]);
        loaded = load_holidays_from_file(filenames[i]);
    }
    
    if (!loaded) {
        printf("祝日データなしで続行します。\n");
    }
    
    printf("\n年を入力してください (例: 2025): ");
    if (scanf("%d", &year) != 1) {
        printf("入力エラー\n");
        return 1;
    }
    
    printf("月を入力してください (1-12): ");
    if (scanf("%d", &month) != 1) {
        printf("入力エラー\n");
        return 1;
    }
    
    if (month < 1 || month > 12) {
        printf("月は1から12の間で入力してください。\n");
        return 1;
    }
    
    print_calendar(year, month);
    
    return 0;
}
C_SOURCE_EOF

echo "✅ C言語コードを修正しました"
echo ""

# ========================================
# リビルドとテスト
# ========================================

echo "🔨 Rebuilding C..."
echo "-----------------------------------"

cd "$PROJECT_ROOT/c"

make clean
make

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🧪 Testing with 2025/5..."
    echo "-----------------------------------"
    echo -e "2025\n5" | ./calendar
    
else
    echo ""
    echo "❌ Build failed"
fi

cd "$PROJECT_ROOT"

echo ""
echo "=========================================="
echo "✨ Fix complete!"
echo "=========================================="
echo ""
echo "📝 Changes made:"
echo "  - Improved CSV parsing with better error handling"
echo "  - Added whitespace trimming for holiday names"
echo "  - Increased buffer sizes"
echo "  - Added validation for date ranges"
echo ""
echo "If still not working, run with DEBUG=1 in code to see details"
echo ""
