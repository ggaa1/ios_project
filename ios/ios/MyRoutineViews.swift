//
//  MyRoutineViews.swift
//  MyRoutine
//
//  PRESENTATION 계층 · SwiftUI 화면
//  탭: 홈 · 기록(수분/수면) · 통계 · 설정
//

import SwiftUI

// MARK: - Root Tab

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }

            RecordView()
                .tabItem { Label("기록", systemImage: "drop.fill") }

            StatsView()
                .tabItem { Label("통계", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
        }
        .accentColor(Theme.water)
    }
}

// MARK: - 홈 (통합 대시보드)

struct HomeView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 인사 + 날짜
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘 · \(Format.todayLabel())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("안녕하세요 👋")
                            .font(.system(size: 26, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 수분 진행률 링
                    ProgressRing(
                        progress: store.todayProgress,
                        color: Theme.water,
                        centerTitle: Format.volume(store.todayTotal),
                        centerSubtitle: "/ \(Format.volume(store.profile.dailyWaterGoal))"
                    )
                    .frame(width: 200, height: 200)
                    .padding(.vertical, 8)

                    // 빠른 추가
                    HStack(spacing: 12) {
                        QuickAddButton(title: "한 잔", amount: 200) { store.addDrink(amount: 200) }
                        QuickAddButton(title: "큰 컵", amount: 350) { store.addDrink(amount: 350) }
                        QuickAddButton(title: "병", amount: 500) { store.addDrink(amount: 500) }
                    }

                    // 어젯밤 수면 요약
                    CardView {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .font(.title2)
                                .foregroundColor(Theme.sleep)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("어젯밤 수면")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let sleep = store.lastSleep {
                                    Text(Format.hoursMinutes(sleep.duration))
                                        .font(.system(size: 20, weight: .bold))
                                } else {
                                    Text("기록 없음")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let sleep = store.lastSleep {
                                StarRatingLabel(rating: sleep.quality)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("MyRoutine", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - 기록 (수분 / 수면 전환)

struct RecordView: View {
    @State private var mode = 0   // 0: 수분, 1: 수면

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $mode) {
                    Text("수분").tag(0)
                    Text("수면").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if mode == 0 {
                    HydrationView()
                } else {
                    SleepView()
                }
            }
            .navigationBarTitle("기록", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - 수분 기록

struct HydrationView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedType: DrinkType = .water

    private var percentText: String {
        "\(Int(store.todayProgress * 100))%"
    }

    var body: some View {
        List {
            // 링 + 빠른 추가
            Section {
                VStack(spacing: 16) {
                    ProgressRing(
                        progress: store.todayProgress,
                        color: Theme.water,
                        centerTitle: Format.volume(store.todayTotal),
                        centerSubtitle: percentText
                    )
                    .frame(width: 170, height: 170)
                    .padding(.top, 8)

                    Picker("종류", selection: $selectedType) {
                        ForEach(DrinkType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack(spacing: 12) {
                        QuickAddButton(title: "한 잔", amount: 200) {
                            store.addDrink(amount: 200, type: selectedType)
                        }
                        QuickAddButton(title: "큰 컵", amount: 350) {
                            store.addDrink(amount: 350, type: selectedType)
                        }
                        QuickAddButton(title: "병", amount: 500) {
                            store.addDrink(amount: 500, type: selectedType)
                        }
                    }

                    Button {
                        store.addDrink(amount: store.profile.cupSize, type: selectedType)
                    } label: {
                        Text("내 컵 +\(store.profile.cupSize)ml")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.water)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 4)
            }

            // 오늘의 기록
            Section(header: Text("오늘의 기록")) {
                if store.todayDrinks.isEmpty {
                    Text("아직 기록이 없어요")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(store.todayDrinks) { log in
                        HStack {
                            Text(Format.time(log.timestamp))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                            Image(systemName: log.drinkType.systemImage)
                                .foregroundColor(Theme.water)
                            Text(log.drinkType.rawValue)
                            Spacer()
                            Text("\(log.amount)ml")
                                .fontWeight(.semibold)
                        }
                    }
                    .onDelete(perform: store.deleteTodayDrinks)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - 수면 기록

struct SleepView: View {
    @EnvironmentObject var store: DataStore

    @State private var bedTime: Date = SleepView.defaultBedTime
    @State private var wakeTime: Date = SleepView.defaultWakeTime
    @State private var quality: Int = 4

    private var duration: Double {
        var interval = wakeTime.timeIntervalSince(bedTime)
        if interval < 0 { interval += 24 * 3600 }
        return interval / 3600.0
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.sleep)
                    Spacer()
                }
                .padding(.vertical, 8)

                DatePicker("취침", selection: $bedTime, displayedComponents: .hourAndMinute)
                DatePicker("기상", selection: $wakeTime, displayedComponents: .hourAndMinute)

                HStack {
                    Text("총 수면")
                    Spacer()
                    Text(Format.hoursMinutes(duration))
                        .font(.headline)
                        .foregroundColor(Theme.sleep)
                }

                HStack {
                    Text("수면의 질")
                    Spacer()
                    StarRating(rating: $quality)
                }
            }

            Section {
                Button {
                    store.addSleep(bedTime: bedTime, wakeTime: wakeTime, quality: quality)
                } label: {
                    Text("수면 기록 저장")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundColor(.white)
                }
                .listRowBackground(Theme.sleep)
            }

            Section(header: Text("최근 기록")) {
                if store.recentSleeps.isEmpty {
                    Text("아직 기록이 없어요")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(store.recentSleeps.prefix(7).map { $0 }) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Format.hoursMinutes(log.duration))
                                    .fontWeight(.semibold)
                                Text("\(Format.time(log.bedTime)) → \(Format.time(log.wakeTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            StarRatingLabel(rating: log.quality)
                        }
                    }
                    .onDelete { offsets in
                        let items = store.recentSleeps.prefix(7).map { $0 }
                        offsets.forEach { store.deleteSleep(items[$0]) }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    private static var defaultBedTime: Date {
        Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: Date()) ?? Date()
    }
    private static var defaultWakeTime: Date {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - 통계

struct StatsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 수분 차트
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("수분 · L", systemImage: "drop.fill")
                                .font(.headline)
                                .foregroundColor(Theme.water)
                            BarChartView(
                                data: store.waterByDay(),
                                color: Theme.water,
                                valueFormat: { String(format: "%.1f", $0) }
                            )
                        }
                    }

                    // 수면 차트
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("수면 · h", systemImage: "moon.fill")
                                .font(.headline)
                                .foregroundColor(Theme.sleep)
                            BarChartView(
                                data: store.sleepByDay(),
                                color: Theme.sleep,
                                valueFormat: { String(format: "%.1f", $0) }
                            )
                        }
                    }

                    // 평균 요약
                    CardView {
                        HStack {
                            summaryItem(
                                title: "평균 수분",
                                value: String(format: "%.1fL", store.averageWater()),
                                color: Theme.water)
                            Divider()
                            summaryItem(
                                title: "평균 수면",
                                value: String(format: "%.1fh", store.averageSleep()),
                                color: Theme.sleep)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("주간 통계", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func summaryItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 설정

struct SettingsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("수분 목표")) {
                    Stepper(
                        "일일 목표 \(Format.volume(store.profile.dailyWaterGoal))",
                        value: $store.profile.dailyWaterGoal, in: 500...5000, step: 100)
                    Stepper(
                        "내 컵 용량 \(store.profile.cupSize)ml",
                        value: $store.profile.cupSize, in: 50...1000, step: 50)
                }

                Section(header: Text("수면 목표")) {
                    Stepper(
                        "목표 수면 \(String(format: "%.1f", store.profile.targetSleepHours))시간",
                        value: $store.profile.targetSleepHours, in: 4...12, step: 0.5)
                }

                Section(header: Text("알림"), footer: Text("모든 데이터는 기기 안에만 저장됩니다. 서버·로그인이 없습니다.")) {
                    Toggle("수분 섭취 알림", isOn: $store.profile.waterReminderOn)
                    if store.profile.waterReminderOn {
                        Stepper(
                            "알림 간격 \(store.profile.reminderInterval)시간마다",
                            value: $store.profile.reminderInterval, in: 1...12, step: 1)
                    }
                    Toggle("취침 알림", isOn: $store.profile.bedtimeReminderOn)
                    if store.profile.bedtimeReminderOn {
                        Stepper(
                            "취침 시각 \(String(format: "%02d:%02d", store.profile.bedtimeHour, store.profile.bedtimeMinute))",
                            value: $store.profile.bedtimeHour, in: 18...26, step: 1)
                    }
                }

                Section {
                    Button("알림 설정 적용") {
                        NotificationService.requestAuthorization { _ in
                            NotificationService.reschedule(for: store.profile)
                        }
                    }
                }
            }
            .navigationBarTitle("설정", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
