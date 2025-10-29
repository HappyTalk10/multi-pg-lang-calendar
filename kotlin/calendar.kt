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
