#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_HOLIDAYS 1100  // 修正: 600 → 1100

typedef struct {
    int year;
    int month;
    int day;
    char name[100];
} Holiday;

Holiday holidays[MAX_HOLIDAYS];
int holiday_count = 0;

const char* weekdays[] = {"日", "月", "火", "水", "木", "金", "土"};

char* trim(char* str) {
    char* end;
    while(isspace((unsigned char)*str)) str++;
    if(*str == 0) return str;
    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    return str;
}

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
    }

    while (fgets(line, sizeof(line), fp) != NULL && holiday_count < MAX_HOLIDAYS) {
        line_num++;
        
        // 改行文字を削除
        line[strcspn(line, "\n")] = 0;
        line[strcspn(line, "\r")] = 0;
        
        // 空行をスキップ
        char* trimmed_line = trim(line);
        if (strlen(trimmed_line) == 0) continue;

        char date_str[50] = "";
        char name[100] = "";
        
        // カンマで分割
        char *comma = strchr(trimmed_line, ',');
        if (comma == NULL) continue;
        
        // 日付部分を取得
        int date_len = comma - trimmed_line;
        if (date_len >= sizeof(date_str) || date_len == 0) continue;
        
        strncpy(date_str, trimmed_line, date_len);
        date_str[date_len] = '\0';
        
        // 名前部分を取得
        strcpy(name, comma + 1);
        
        // 両方をトリム
        char* clean_date = trim(date_str);
        char* clean_name = trim(name);
        
        if (strlen(clean_date) == 0 || strlen(clean_name) == 0) continue;
        
        // 日付をパース
        int year = 0, month = 0, day = 0;
        int parsed = 0;
        
        // 形式1: YYYY/MM/DD または YYYY/M/D
        if (sscanf(clean_date, "%d/%d/%d", &year, &month, &day) == 3) {
            parsed = 1;
        }
        // 形式2: YYYY-MM-DD または YYYY-M-D
        else if (sscanf(clean_date, "%d-%d-%d", &year, &month, &day) == 3) {
            parsed = 1;
        }
        
        if (parsed && year >= 1900 && year <= 2100 && 
            month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            
            holidays[holiday_count].year = year;
            holidays[holiday_count].month = month;
            holidays[holiday_count].day = day;
            strncpy(holidays[holiday_count].name, clean_name, sizeof(holidays[holiday_count].name) - 1);
            holidays[holiday_count].name[sizeof(holidays[holiday_count].name) - 1] = '\0';
            
            holiday_count++;
        }
    }

    fclose(fp);
    printf("祝日データを読み込みました: %d件\n", holiday_count);
    
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
    
    const char* filenames[] = {
        "holidays.csv",
        "../data/holidays.csv",
        "data/holidays.csv"
    };
    
    int loaded = 0;
    for (int i = 0; i < 3 && !loaded; i++) {
        loaded = load_holidays_from_file(filenames[i]);
        if (loaded) break;
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
