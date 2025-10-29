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
        
        // ヘッダー行をスキップ
        if line_num == 1 {
            continue;
        }
        
        let trimmed_line = line.trim();
        
        // 空行をスキップ
        if trimmed_line.is_empty() {
            continue;
        }

        let parts: Vec<&str> = trimmed_line.split(',').collect();
        if parts.len() < 2 {
            continue;
        }

        let date_str = parts[0].trim().replace('/', "-");
        let name = parts[1].trim().to_string();

        // 日付が空の場合はスキップ
        if date_str.is_empty() || name.is_empty() {
            continue;
        }

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
                // 有効な日付範囲チェック
                if year >= 1900 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31 {
                    holidays.push(Holiday { year, month, day, name });
                }
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
