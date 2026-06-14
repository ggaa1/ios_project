//
//  MyRoutineCore.swift
//  MyRoutine
//
//  모델 · 로컬 영속 저장소 · 알림 서비스 (DATA / LOGIC 계층)
//
//  계획서의 SwiftData(@Model) 대신, iOS 14.5에서 동작하도록
//  Codable + JSON 로컬 파일 저장으로 동일한 온디바이스 저장을 구현한다.
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - Models (계획서의 세 엔티티)

/// 음료 종류
enum DrinkType: String, Codable, CaseIterable, Identifiable {
    case water = "물"
    case coffee = "커피"
    case tea = "차"
    case juice = "주스"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .water:  return "drop.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .tea:    return "leaf.fill"
        case .juice:  return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

/// 사용자 설정 기준 (UserProfile)
struct UserProfile: Codable {
    var id: UUID = UUID()
    var dailyWaterGoal: Int = 2000      // ml
    var targetSleepHours: Double = 8.0  // h
    var reminderInterval: Int = 2       // 수분 알림 간격(시간)
    var cupSize: Int = 200              // ml
    var waterReminderOn: Bool = false
    var bedtimeReminderOn: Bool = false
    var bedtimeHour: Int = 23
    var bedtimeMinute: Int = 0
}

/// 수분 기록 (DrinkLog)
struct DrinkLog: Codable, Identifiable {
    var id: UUID = UUID()
    var amount: Int                 // ml
    var timestamp: Date
    var drinkType: DrinkType
}

/// 수면 기록 (SleepLog)
struct SleepLog: Codable, Identifiable {
    var id: UUID = UUID()
    var bedTime: Date
    var wakeTime: Date
    var quality: Int                // 1...5

    /// 총 수면 시간(시간 단위). 기상이 취침보다 이르면 다음날로 간주.
    var duration: Double {
        var interval = wakeTime.timeIntervalSince(bedTime)
        if interval < 0 { interval += 24 * 3600 }
        return interval / 3600.0
    }
}

// MARK: - Persistence Container

private struct StoreData: Codable {
    var profile: UserProfile
    var drinks: [DrinkLog]
    var sleeps: [SleepLog]
}

// MARK: - DataStore (ViewModel / 로컬 영속 저장소)

final class DataStore: ObservableObject {
    @Published var profile: UserProfile { didSet { save() } }
    @Published var drinks: [DrinkLog]   { didSet { save() } }
    @Published var sleeps: [SleepLog]   { didSet { save() } }

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("myroutine_store.json")

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(StoreData.self, from: data) {
            profile = decoded.profile
            drinks  = decoded.drinks
            sleeps  = decoded.sleeps
        } else {
            profile = UserProfile()
            drinks  = []
            sleeps  = []
        }
    }

    private func save() {
        let payload = StoreData(profile: profile, drinks: drinks, sleeps: sleeps)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: 수분 CRUD

    func addDrink(amount: Int, type: DrinkType = .water, at date: Date = Date()) {
        drinks.append(DrinkLog(amount: amount, timestamp: date, drinkType: type))
    }

    func deleteDrink(_ log: DrinkLog) {
        drinks.removeAll { $0.id == log.id }
    }

    func deleteTodayDrinks(at offsets: IndexSet) {
        let today = todayDrinks
        let ids = offsets.map { today[$0].id }
        drinks.removeAll { ids.contains($0.id) }
    }

    // MARK: 수면 CRUD

    func addSleep(bedTime: Date, wakeTime: Date, quality: Int) {
        sleeps.append(SleepLog(bedTime: bedTime, wakeTime: wakeTime, quality: quality))
    }

    func deleteSleep(_ log: SleepLog) {
        sleeps.removeAll { $0.id == log.id }
    }

    // MARK: 조회 (대시보드 / 통계)

    private let cal = Calendar.current

    var todayDrinks: [DrinkLog] {
        drinks
            .filter { cal.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// 오늘 누적 섭취량(ml)
    var todayTotal: Int {
        todayDrinks.reduce(0) { $0 + $1.amount }
    }

    /// 목표 대비 진행률 0...1
    var todayProgress: Double {
        guard profile.dailyWaterGoal > 0 else { return 0 }
        return min(Double(todayTotal) / Double(profile.dailyWaterGoal), 1.0)
    }

    /// 어젯밤(가장 최근) 수면 기록
    var lastSleep: SleepLog? {
        sleeps.sorted { $0.wakeTime > $1.wakeTime }.first
    }

    var recentSleeps: [SleepLog] {
        sleeps.sorted { $0.wakeTime > $1.wakeTime }
    }

    /// 최근 N일 일별 수분 합계(ml). 오늘이 마지막 원소.
    func waterByDay(days: Int = 7) -> [DaySummary] {
        let start = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: start)!
            let total = drinks
                .filter { cal.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            return DaySummary(date: day, value: Double(total) / 1000.0) // L
        }
    }

    /// 최근 N일 일별 수면 시간(h). 기상일 기준.
    func sleepByDay(days: Int = 7) -> [DaySummary] {
        let start = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: start)!
            let hours = sleeps
                .filter { cal.isDate($0.wakeTime, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.duration }
            return DaySummary(date: day, value: hours)
        }
    }

    /// 최근 N일 평균 수분(L)
    func averageWater(days: Int = 7) -> Double {
        let vals = waterByDay(days: days).map { $0.value }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Double(vals.count)
    }

    /// 기록이 있는 날만 대상으로 한 평균 수면(h)
    func averageSleep(days: Int = 7) -> Double {
        let vals = sleepByDay(days: days).map { $0.value }.filter { $0 > 0 }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Double(vals.count)
    }
}

/// 통계용 일별 집계 단위
struct DaySummary: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double

    /// 요일 한 글자 (월,화,...)
    var weekdayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "EEEEE"
        return f.string(from: date)
    }
}

// MARK: - NotificationService (알림 서비스)

enum NotificationService {

    static func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async { completion?(granted) }
            }
    }

    /// 프로필 설정에 맞춰 모든 알림을 다시 스케줄링한다.
    static func reschedule(for profile: UserProfile) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // 수분 섭취 리마인더 (간격 반복)
        if profile.waterReminderOn {
            let content = UNMutableNotificationContent()
            content.title = "수분 섭취 시간 💧"
            content.body  = "물 한 잔 마실 시간이에요. 오늘 목표를 채워볼까요?"
            content.sound = .default

            let seconds = max(profile.reminderInterval, 1) * 3600
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(seconds), repeats: true)
            center.add(UNNotificationRequest(
                identifier: "water.reminder", content: content, trigger: trigger))
        }

        // 취침 리마인더 (매일 지정 시각)
        if profile.bedtimeReminderOn {
            let content = UNMutableNotificationContent()
            content.title = "취침 시간 🌙"
            content.body  = "잘 준비를 할 시간이에요. 규칙적인 수면을 지켜보세요."
            content.sound = .default

            var date = DateComponents()
            date.hour = profile.bedtimeHour % 24
            date.minute = profile.bedtimeMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            center.add(UNNotificationRequest(
                identifier: "bedtime.reminder", content: content, trigger: trigger))
        }
    }
}
