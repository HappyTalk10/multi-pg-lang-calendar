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
