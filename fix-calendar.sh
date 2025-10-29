#!/bin/bash

# ========================================
# Multi-PG-Lang Calendar - 修正パッチ
# 問題: 日曜日に常にアスタリスク、C言語で祝日非表示
# ========================================

echo "🔧 Applying fixes to calendar programs..."
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
# C言語の修正
# ========================================

echo "📝 Fixing C implementation..."
echo "-----------------------------------"

cat > c/calendar.c << 'C_SOURCE_EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_HOLIDAYS 500

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
        printf("\n【ファイルの作成方法】\n");
        printf("1. 内閣府の祝日CSVをダウンロード:\n");
        printf("   https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv\n");
        printf("2. UTF-8に変換してください\n");
        return 0;
    }

    char line[256];
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
        if (strlen(line) == 0) continue;

        char date_str[20];
        char name[100];
        
        // カンマで分割
        char *comma = strchr(line, ',');
        if (comma == NULL) continue;
        
        int date_len = comma - line;
        strncpy(date_str, line, date_len);
        date_str[date_len] = '\0';
        strcpy(name, comma + 1);
        
        // 日付をパース
        int year, month, day;
        if (sscanf(date_str, "%d-%d-%d", &year, &month, &day) == 3 ||
            sscanf(date_str, "%d/%d/%d", &year, &month, &day) == 3) {
            holidays[holiday_count].year = year;
            holidays[holiday_count].month = month;
            holidays[holiday_count].day = day;
            strncpy(holidays[holiday_count].name, name, sizeof(holidays[holiday_count].name) - 1);
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
    
    // 月初めまでの空白
    for (int i = 0; i < first_day; i++) {
        printf("    ");
    }
    
    int current_weekday = first_day;
    for (int day = 1; day <= days_in_month; day++) {
        int is_hol = is_holiday(year, month, day, NULL);
        
        // 修正: 祝日の場合のみアスタリスクをつける
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
    
    // 修正: 相対パスと絶対パスの両方を試す
    const char* filenames[] = {
        "holidays.csv",
        "../data/holidays.csv",
        "data/holidays.csv"
    };
    
    int loaded = 0;
    for (int i = 0; i < 3 && !loaded; i++) {
        printf("Trying to load: %s\n", filenames[i]);
        loaded = load_holidays_from_file(filenames[i]);
    }
    
    if (!loaded) {
        printf("祝日データなしで続行します。\n");
    }
    
    printf("\n年を入力してください (例: 2025): ");
    scanf("%d", &year);
    
    printf("月を入力してください (1-12): ");
    scanf("%d", &month);
    
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
# Go言語の修正
# ========================================

echo "📝 Fixing Go implementation..."
echo "-----------------------------------"

cat > go/calendar.go << 'GO_SOURCE_EOF'
package main

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

type Holiday struct {
	Year  int
	Month int
	Day   int
	Name  string
}

var holidays []Holiday
var weekdays = []string{"日", "月", "火", "水", "木", "金", "土"}

const holidayURL = "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"
const holidayFile = "holidays.csv"

func downloadAndConvertHolidayFile() error {
	fmt.Println("内閣府から祝日データをダウンロード中...")
	
	resp, err := http.Get(holidayURL)
	if err != nil {
		return fmt.Errorf("ダウンロードエラー: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTPエラー: %d", resp.StatusCode)
	}

	tmpFile := "holidays_sjis.csv"
	out, err := os.Create(tmpFile)
	if err != nil {
		return fmt.Errorf("ファイル作成エラー: %v", err)
	}

	_, err = io.Copy(out, resp.Body)
	out.Close()
	if err != nil {
		return fmt.Errorf("保存エラー: %v", err)
	}

	cmd := exec.Command("iconv", "-f", "SHIFT_JIS", "-t", "UTF-8", tmpFile)
	output, err := cmd.Output()
	if err != nil {
		os.Rename(tmpFile, holidayFile)
		fmt.Println("⚠️  UTF-8変換をスキップしました")
	} else {
		err = os.WriteFile(holidayFile, output, 0644)
		if err != nil {
			return fmt.Errorf("UTF-8ファイル作成エラー: %v", err)
		}
		os.Remove(tmpFile)
		fmt.Println("✅ UTF-8に変換しました")
	}

	fmt.Printf("祝日データを保存しました: %s\n", holidayFile)
	return nil
}

func loadHolidaysFromFile(filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineNum := 0
	
	if scanner.Scan() {
		lineNum++
	}

	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())
		
		if line == "" {
			continue
		}

		parts := strings.Split(line, ",")
		if len(parts) < 2 {
			continue
		}

		dateStr := strings.TrimSpace(parts[0])
		name := strings.TrimSpace(parts[1])

		dateStr = strings.ReplaceAll(dateStr, "/", "-")
		dateParts := strings.Split(dateStr, "-")
		
		if len(dateParts) != 3 {
			continue
		}

		year, err1 := strconv.Atoi(dateParts[0])
		month, err2 := strconv.Atoi(dateParts[1])
		day, err3 := strconv.Atoi(dateParts[2])

		if err1 != nil || err2 != nil || err3 != nil {
			continue
		}

		holidays = append(holidays, Holiday{
			Year:  year,
			Month: month,
			Day:   day,
			Name:  name,
		})
	}

	return scanner.Err()
}

func isHoliday(year, month, day int) (bool, string) {
	for _, h := range holidays {
		if h.Year == year && h.Month == month && h.Day == day {
			return true, h.Name
		}
	}
	return false, ""
}

func printCalendar(year, month int) {
	fmt.Printf("\n        %d年 %d月\n", year, month)
	fmt.Println("----------------------------")

	for _, wd := range weekdays {
		fmt.Printf(" %s ", wd)
	}
	fmt.Println()
	fmt.Println("----------------------------")

	firstDay := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)
	firstWeekday := int(firstDay.Weekday())
	
	lastDay := firstDay.AddDate(0, 1, -1)
	daysInMonth := lastDay.Day()

	for i := 0; i < firstWeekday; i++ {
		fmt.Print("    ")
	}

	currentWeekday := firstWeekday
	for day := 1; day <= daysInMonth; day++ {
		isHol, _ := isHoliday(year, month, day)
		
		// 修正: 祝日の場合のみアスタリスクをつける
		if isHol {
			fmt.Printf("%3d*", day)
		} else {
			fmt.Printf("%3d ", day)
		}

		currentWeekday++
		if currentWeekday == 7 {
			fmt.Println()
			currentWeekday = 0
		}
	}

	if currentWeekday != 0 {
		fmt.Println()
	}
	fmt.Println("----------------------------")

	fmt.Println("\n【祝日】")
	found := false
	for _, h := range holidays {
		if h.Year == year && h.Month == month {
			fmt.Printf("  %2d日: %s\n", h.Day, h.Name)
			found = true
		}
	}
	if !found {
		fmt.Println("  なし")
	}
	fmt.Println()
}

func main() {
	fmt.Println("=== 月間カレンダー（祝日対応版）Go言語 ===\n")

	err := loadHolidaysFromFile(holidayFile)
	if err != nil {
		fmt.Printf("ローカルファイル '%s' が見つかりません。\n", holidayFile)
		fmt.Print("内閣府から祝日データをダウンロードしますか？ (y/n): ")
		
		var response string
		fmt.Scan(&response)
		
		if strings.ToLower(response) == "y" {
			if err := downloadAndConvertHolidayFile(); err != nil {
				fmt.Printf("ダウンロード失敗: %v\n", err)
				fmt.Println("祝日データなしで続行します。")
			} else {
				if err := loadHolidaysFromFile(holidayFile); err != nil {
					fmt.Printf("読み込みエラー: %v\n", err)
				} else {
					fmt.Printf("祝日データを読み込みました: %d件\n", len(holidays))
				}
			}
		} else {
			fmt.Println("祝日データなしで続行します。")
		}
	} else {
		fmt.Printf("祝日データを読み込みました: %d件\n", len(holidays))
	}

	var year, month int
	fmt.Print("\n年を入力してください (例: 2025): ")
	fmt.Scan(&year)

	fmt.Print("月を入力してください (1-12): ")
	fmt.Scan(&month)

	if month < 1 || month > 12 {
		fmt.Println("月は1から12の間で入力してください。")
		return
	}

	printCalendar(year, month)
}
GO_SOURCE_EOF

echo "✅ Go言語コードを修正しました"
echo ""

# ========================================
# Kotlinの修正
# ========================================

echo "📝 Fixing Kotlin implementation..."
echo "-----------------------------------"

cat > kotlin/calendar.kt << 'KOTLIN_SOURCE_EOF'
import java.io.File
import java.net.URL
import java.time.LocalDate

data class Holiday(
    val year: Int,
    val month: Int,
    val day: Int,
    val name: String
)

val weekdays = arrayOf("日", "月", "火", "水", "木", "金", "土")
val holidays = mutableListOf<Holiday>()

const val HOLIDAY_URL = "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"
const val HOLIDAY_FILE = "holidays.csv"

fun downloadAndConvertHolidayFile(): Boolean {
    return try {
        println("内閣府から祝日データをダウンロード中...")
        
        val content = URL(HOLIDAY_URL).readBytes()
        
        val text = try {
            String(content, charset("Shift_JIS"))
        } catch (e: Exception) {
            String(content, Charsets.UTF_8)
        }
        
        File(HOLIDAY_FILE).writeText(text, Charsets.UTF_8)
        println("祝日データを保存しました: $HOLIDAY_FILE")
        true
    } catch (e: Exception) {
        println("ダウンロードエラー: ${e.message}")
        false
    }
}

fun loadHolidaysFromFile(filename: String): Boolean {
    val file = File(filename)
    if (!file.exists()) {
        return false
    }

    try {
        val lines = file.readLines(Charsets.UTF_8)
        var lineNum = 0

        for (line in lines) {
            lineNum++
            if (lineNum == 1) continue
            
            val trimmedLine = line.trim()
            if (trimmedLine.isEmpty()) continue

            val parts = trimmedLine.split(",")
            if (parts.size < 2) continue

            val dateStr = parts[0].trim().replace("/", "-")
            val name = parts[1].trim()

            try {
                val dateParts = dateStr.split("-")
                if (dateParts.size != 3) continue

                val year = dateParts[0].toInt()
                val month = dateParts[1].toInt()
                val day = dateParts[2].toInt()

                holidays.add(Holiday(year, month, day, name))
            } catch (e: NumberFormatException) {
                // Skip invalid lines
            }
        }
        return true
    } catch (e: Exception) {
        println("ファイル読み込みエラー: ${e.message}")
        return false
    }
}

fun isHoliday(year: Int, month: Int, day: Int): Pair<Boolean, String> {
    val holiday = holidays.find { it.year == year && it.month == month && it.day == day }
    return if (holiday != null) {
        Pair(true, holiday.name)
    } else {
        Pair(false, "")
    }
}

fun printCalendar(year: Int, month: Int) {
    println("\n        ${year}年 ${month}月")
    println("----------------------------")

    weekdays.forEach { print(" $it ") }
    println()
    println("----------------------------")

    val firstDay = LocalDate.of(year, month, 1)
    val firstWeekday = firstDay.dayOfWeek.value % 7
    val daysInMonth = firstDay.lengthOfMonth()

    repeat(firstWeekday) {
        print("    ")
    }

    var currentWeekday = firstWeekday
    for (day in 1..daysInMonth) {
        val (isHol, _) = isHoliday(year, month, day)
        
        // 修正: 祝日の場合のみアスタリスクをつける
        if (isHol) {
            print("%3d*".format(day))
        } else {
            print("%3d ".format(day))
        }

        currentWeekday++
        if (currentWeekday == 7) {
            println()
            currentWeekday = 0
        }
    }

    if (currentWeekday != 0) {
        println()
    }
    println("----------------------------")

    println("\n【祝日】")
    val monthHolidays = holidays.filter { it.year == year && it.month == month }
    if (monthHolidays.isEmpty()) {
        println("  なし")
    } else {
        monthHolidays.sortedBy { it.day }.forEach {
            println("  %2d日: %s".format(it.day, it.name))
        }
    }
    println()
}

fun main() {
    println("=== 月間カレンダー(祝日対応版)Kotlin ===\n")

    if (!loadHolidaysFromFile(HOLIDAY_FILE)) {
        println("ローカルファイル '$HOLIDAY_FILE' が見つかりません。")
        print("内閣府から祝日データをダウンロードしますか？ (y/n): ")
        
        val response = readLine()?.trim()?.lowercase()
        
        if (response == "y") {
            if (downloadAndConvertHolidayFile()) {
                if (loadHolidaysFromFile(HOLIDAY_FILE)) {
                    println("祝日データを読み込みました: ${holidays.size}件")
                } else {
                    println("読み込みエラーが発生しました")
                }
            } else {
                println("祝日データなしで続行します。")
            }
        } else {
            println("祝日データなしで続行します。")
        }
    } else {
        println("祝日データを読み込みました: ${holidays.size}件")
    }

    print("\n年を入力してください (例: 2025): ")
    val year = readLine()?.toIntOrNull() ?: 2025

    print("月を入力してください (1-12): ")
    val month = readLine()?.toIntOrNull() ?: 1

    if (month !in 1..12) {
        println("月は1から12の間で入力してください。")
        return
    }

    printCalendar(year, month)
}
KOTLIN_SOURCE_EOF

echo "✅ Kotlin言語コードを修正しました"
echo ""

# ========================================
# Rustの修正
# ========================================

echo "📝 Fixing Rust implementation..."
echo "-----------------------------------"

cat > rust/src/main.rs << 'RUST_SOURCE_EOF'
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};

#[derive(Debug, Clone)]
struct Holiday {
    year: i32,
    month: i32,
    day: i32,
    name: String,
}

const WEEKDAYS: [&str; 7] = ["日", "月", "火", "水", "木", "金", "土"];
const HOLIDAY_URL: &str = "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv";
const HOLIDAY_FILE: &str = "holidays.csv";

fn download_and_convert_holiday_file() -> Result<(), Box<dyn std::error::Error>> {
    println!("内閣府から祝日データをダウンロード中...");
    
    let response = reqwest::blocking::get(HOLIDAY_URL)?;
    let bytes = response.bytes()?;
    
    let (decoded, _, _) = encoding_rs::SHIFT_JIS.decode(&bytes);
    
    let mut file = File::create(HOLIDAY_FILE)?;
    file.write_all(decoded.as_bytes())?;
    
    println!("祝日データを保存しました: {}", HOLIDAY_FILE);
    println!("✅ UTF-8に変換しました");
    Ok(())
}

fn load_holidays_from_file(filename: &str) -> Result<Vec<Holiday>, Box<dyn std::error::Error>> {
    let file = File::open(filename)?;
    let reader = BufReader::new(file);
    let mut holidays = Vec::new();
    let mut line_num = 0;

    for line in reader.lines() {
        line_num += 1;
        let line = line?;
        
        if line_num == 1 {
            continue;
        }
        
        let trimmed_line = line.trim();
        if trimmed_line.is_empty() {
            continue;
        }

        let parts: Vec<&str> = trimmed_line.split(',').collect();
        if parts.len() < 2 {
            continue;
        }

        let date_str = parts[0].trim().replace('/', "-");
        let name = parts[1].trim().to_string();

        let date_parts: Vec<&str> = date_str.split('-').collect();
        if date_parts.len() != 3 {
            continue;
        }

        match (
            date_parts[0].parse::<i32>(),
            date_parts[1].parse::<i32>(),
            date_parts[2].parse::<i32>(),
        ) {
            (Ok(year), Ok(month), Ok(day)) => {
                holidays.push(Holiday { year, month, day, name });
            }
            _ => {}
        }
    }

    Ok(holidays)
}

fn is_holiday(holidays: &[Holiday], year: i32, month: i32, day: i32) -> Option<String> {
    holidays
        .iter()
        .find(|h| h.year == year && h.month == month && h.day == day)
        .map(|h| h.name.clone())
}

fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

fn get_days_in_month(year: i32, month: i32) -> i32 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => if is_leap_year(year) { 29 } else { 28 },
        _ => 0,
    }
}

fn get_weekday(year: i32, month: i32, day: i32) -> i32 {
    let mut y = year;
    let mut m = month;
    
    if m < 3 {
        y -= 1;
        m += 12;
    }
    
    let h = (day + (13 * (m + 1)) / 5 + y + y / 4 - y / 100 + y / 400) % 7;
    (h + 6) % 7
}

fn print_calendar(holidays: &[Holiday], year: i32, month: i32) {
    println!("\n        {}年 {}月", year, month);
    println!("----------------------------");

    for wd in WEEKDAYS.iter() {
        print!(" {} ", wd);
    }
    println!();
    println!("----------------------------");

    let first_weekday = get_weekday(year, month, 1);
    let days_in_month = get_days_in_month(year, month);

    for _ in 0..first_weekday {
        print!("    ");
    }

    let mut current_weekday = first_weekday;
    for day in 1..=days_in_month {
        let is_hol = is_holiday(holidays, year, month, day).is_some();
        
        // 修正: 祝日の場合のみアスタリスクをつける
        if is_hol {
            print!("{:3}*", day);
        } else {
            print!("{:3} ", day);
        }

        current_weekday += 1;
        if current_weekday == 7 {
            println!();
            current_weekday = 0;
        }
    }

    if current_weekday != 0 {
        println!();
    }
    println!("----------------------------");

    println!("\n【祝日】");
    let mut month_holidays: Vec<_> = holidays
        .iter()
        .filter(|h| h.year == year && h.month == month)
        .collect();
    
    month_holidays.sort_by_key(|h| h.day);
    
    if month_holidays.is_empty() {
        println!("  なし");
    } else {
        for h in month_holidays {
            println!("  {:2}日: {}", h.day, h.name);
        }
    }
    println!();
}

fn read_line() -> String {
    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap();
    input.trim().to_string()
}

fn main() {
    println!("=== 月間カレンダー（祝日対応版）Rust ===\n");

    let mut holidays = Vec::new();
    
    match load_holidays_from_file(HOLIDAY_FILE) {
        Ok(data) => {
            holidays = data;
            println!("祝日データを読み込みました: {}件", holidays.len());
        }
        Err(_) => {
            println!("ローカルファイル '{}' が見つかりません。", HOLIDAY_FILE);
            print!("内閣府から祝日データをダウンロードしますか？ (y/n): ");
            io::stdout().flush().unwrap();
            
            let response = read_line();
            
            if response.to_lowercase() == "y" {
                match download_and_convert_holiday_file() {
                    Ok(_) => {
                        match load_holidays_from_file(HOLIDAY_FILE) {
                            Ok(data) => {
                                holidays = data;
                                println!("祝日データを読み込みました: {}件", holidays.len());
                            }
                            Err(e) => {
                                println!("読み込みエラー: {}", e);
                            }
                        }
                    }
                    Err(e) => {
                        println!("ダウンロードエラー: {}", e);
                        println!("祝日データなしで続行します。");
                    }
                }
            } else {
                println!("祝日データなしで続行します。");
            }
        }
    }

    print!("\n年を入力してください (例: 2025): ");
    io::stdout().flush().unwrap();
    let year: i32 = read_line().parse().unwrap_or(2025);

    print!("月を入力してください (1-12): ");
    io::stdout().flush().unwrap();
    let month: i32 = read_line().parse().unwrap_or(1);

    if !(1..=12).contains(&month) {
        println!("月は1から12の間で入力してください。");
        return;
    }

    print_calendar(&holidays, year, month);
}
RUST_SOURCE_EOF

echo "✅ Rust言語コードを修正しました"
echo ""

# ========================================
# 完了メッセージ
# ========================================

echo "=========================================="
echo "✨ 修正完了!"
echo "=========================================="
echo ""
echo "📝 修正内容:"
echo "-----------------------------------"
echo "1. ✅ 日曜日の無条件アスタリスク削除"
echo "   → 祝日のみアスタリスク表示"
echo ""
echo "2. ✅ C言語のファイルパス修正"
echo "   → 複数パスを自動検索"
echo ""
echo "3. ✅ 全言語で同じロジックに統一"
echo ""
echo "📋 次のステップ:"
echo "-----------------------------------"
echo "  1. リビルド:"
echo "     ./scripts/build-all.sh"
echo ""
echo "  2. テスト:"
echo "     ./scripts/test-all.sh"
echo ""
echo "  3. 個別テスト (2025年5月):"
echo "     cd c && echo -e '2025\n5' | ./calendar"
echo "     cd go && echo -e '2025\n5' | ./calendar"
echo "     cd kotlin && echo -e '2025\n5' | java -jar calendar.jar"
echo "     cd rust && echo -e '2025\n5' | ./target/release/calendar"
echo ""
echo "=========================================="
