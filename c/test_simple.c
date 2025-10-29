#include <stdio.h>
#include <string.h>

int main() {
    FILE *fp = fopen("holidays.csv", "r");
    if (fp == NULL) {
        printf("❌ ファイルを開けません\n");
        return 1;
    }
    
    printf("✅ ファイルを開きました\n\n");
    
    char line[512];
    int line_num = 0;
    int found_2025_5 = 0;
    
    while (fgets(line, sizeof(line), fp) != NULL) {
        line_num++;
        
        // 2025/5/を含む行を探す
        if (strstr(line, "2025/5/") != NULL) {
            found_2025_5++;
            printf("=== Line %d ===\n", line_num);
            printf("内容: %s", line);
            printf("長さ: %lu\n", strlen(line));
            
            // 各文字を表示
            printf("文字コード: ");
            for (int i = 0; i < strlen(line) && i < 30; i++) {
                printf("%02X ", (unsigned char)line[i]);
            }
            printf("\n");
            
            // パース試行
            char date[20], name[100];
            if (sscanf(line, "%[^,],%[^\n]", date, name) == 2) {
                printf("✅ 分割成功\n");
                printf("  日付: [%s]\n", date);
                printf("  名前: [%s]\n", name);
                
                int year, month, day;
                if (sscanf(date, "%d/%d/%d", &year, &month, &day) == 3) {
                    printf("✅ パース成功: %d年%d月%d日\n", year, month, day);
                } else {
                    printf("❌ パース失敗\n");
                }
            } else {
                printf("❌ 分割失敗\n");
            }
            printf("\n");
        }
    }
    
    fclose(fp);
    
    printf("========================================\n");
    printf("2025/5/ を含む行数: %d\n", found_2025_5);
    printf("========================================\n");
    
    return 0;
}
