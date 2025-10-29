#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_HOLIDAYS 600

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
        printf("❌ ファイルを開けません: %s\n", filename);
        return 0;
    }

    printf("✅ ファイルを開きました: %s\n", filename);

    char line[512];
    int line_num = 0;
    int lines_2025_may = 0;
    
    // ヘッダー行
    if (fgets(line, sizeof(line), fp) != NULL) {
        line_num++;
        printf("Header (line %d): %s", line_num, line);
    }

    while (fgets(line, sizeof(line), fp) != NULL && holiday_count < MAX_HOLIDAYS) {
        line_num++;
        
        // 改行削除
        line[strcspn(line, "\n")] = 0;
        line[strcspn(line, "\r")] = 0;
        
        char* trimmed = trim(line);
        if (strlen(trimmed) == 0) continue;

        // 2025年5月のデータを詳細表示
        int is_2025_5 = (strstr(trimmed, "2025") != NULL && 
                         (strstr(trimmed, "/5/") != NULL || strstr(trimmed, "-5-") != NULL));
        
        if (is_2025_5) {
            printf("\n=== Line %d (2025年5月候補) ===\n", line_num);
            printf("Raw: [%s]\n", trimmed);
            printf("Length: %lu\n", strlen(trimmed));
        }

        // カンマで分割
        char *comma = strchr(trimmed, ',');
        if (comma == NULL) {
            if (is_2025_5) printf("❌ カンマなし\n");
            continue;
        }

        if (is_2025_5) {
            printf("✅ カンマ位置: %ld\n", comma - trimmed);
        }

        // 日付と名前を分離
        char date_str[50];
        int date_len = comma - trimmed;
        
        if (date_len >= sizeof(date_str) || date_len == 0) {
            if (is_2025_5) printf("❌ 日付長さ異常: %d\n", date_len);
            continue;
        }
        
        strncpy(date_str, trimmed, date_len);
        date_str[date_len] = '\0';
        
        char name[100];
        strcpy(name, comma + 1);
        
        char* clean_date = trim(date_str);
        char* clean_name = trim(name);
        
        if (is_2025_5) {
            printf("日付部分: [%s]\n", clean_date);
            printf("名前部分: [%s]\n", clean_name);
        }
        
        if (strlen(clean_date) == 0 || strlen(clean_name) == 0) {
            if (is_2025_5) printf("❌ 空フィールド\n");
            continue;
        }

        // 日付パース
        int year = 0, month = 0, day = 0;
        int parsed = 0;
        
        // スラッシュ形式
        int result = sscanf(clean_date, "%d/%d/%d", &year, &month, &day);
        if (result == 3) {
            parsed = 1;
            if (is_2025_5) {
                printf("✅ パース成功 (slash): year=%d month=%d day=%d\n", year, month, day);
            }
        } else {
            // ハイフン形式
            result = sscanf(clean_date, "%d-%d-%d", &year, &month, &day);
            if (result == 3) {
                parsed = 1;
                if (is_2025_5) {
                    printf("✅ パース成功 (hyphen): year=%d month=%d day=%d\n", year, month, day);
                }
            } else {
                if (is_2025_5) {
                    printf("❌ パース失敗: sscanf result=%d\n", result);
                }
            }
        }
        
        // バリデーション
        if (parsed) {
            int valid = (year >= 1900 && year <= 2100 && 
                        month >= 1 && month <= 12 && 
                        day >= 1 && day <= 31);
            
            if (is_2025_5) {
                if (valid) {
                    printf("✅ バリデーション成功\n");
                } else {
                    printf("❌ バリデーション失敗: year=%d month=%d day=%d\n", year, month, day);
                }
            }
            
            if (valid) {
                holidays[holiday_count].year = year;
                holidays[holiday_count].month = month;
                holidays[holiday_count].day = day;
                strncpy(holidays[holiday_count].name, clean_name, sizeof(holidays[holiday_count].name) - 1);
                holidays[holiday_count].name[sizeof(holidays[holiday_count].name) - 1] = '\0';
                
                if (is_2025_5) {
                    printf("✅ 配列に追加: holidays[%d]\n", holiday_count);
                    lines_2025_may++;
                }
                
                holiday_count++;
            }
        }
        
        if (is_2025_5) {
            printf("==============================\n");
        }
    }

    fclose(fp);
    
    printf("\n総読み込み件数: %d件\n", holiday_count);
    printf("2025年5月として処理した行数: %d件\n", lines_2025_may);
    
    // 最終確認
    printf("\n=== 配列内の2025年5月データ確認 ===\n");
    int found = 0;
    for (int i = 0; i < holiday_count; i++) {
        if (holidays[i].year == 2025 && holidays[i].month == 5) {
            printf("holidays[%d]: %d/%d/%d %s\n", 
                   i, holidays[i].year, holidays[i].month, holidays[i].day, holidays[i].name);
            found++;
        }
    }
    if (found == 0) {
        printf("(なし)\n");
    }
    printf("=====================================\n\n");
    
    return 1;
}

int main() {
    printf("=== C言語パーサー詳細デバッグ ===\n\n");
    
    load_holidays_from_file("holidays.csv");
    
    return 0;
}
