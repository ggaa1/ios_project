//
//  MyRoutineComponents.swift
//  MyRoutine
//
//  공용 디자인 토큰 & 재사용 컴포넌트
//  (Swift Charts 대신 SwiftUI로 직접 구현한 진행률 링 / 막대 차트)
//

import SwiftUI

// MARK: - Theme

enum Theme {
    /// 수분 메인 컬러 (계획서 파란색 계열)
    static let water = Color(red: 0.18, green: 0.49, blue: 0.96)
    /// 수면 메인 컬러 (보라색 계열)
    static let sleep = Color(red: 0.49, green: 0.44, blue: 0.94)
    static let track = Color(red: 0.90, green: 0.92, blue: 0.96)
    static let cardBackground = Color(.secondarySystemBackground)
}

// MARK: - 진행률 링 (대시보드 / 수분 화면)

struct ProgressRing: View {
    var progress: Double          // 0...1
    var lineWidth: CGFloat = 16
    var color: Color = Theme.water
    var centerTitle: String
    var centerSubtitle: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            VStack(spacing: 4) {
                Text(centerTitle)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(centerSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 막대 차트 (통계 화면, Swift Charts 대체)

struct BarChartView: View {
    var data: [DaySummary]
    var color: Color
    /// 값 포맷 (예: "1.7L", "7.2h")
    var valueFormat: (Double) -> String
    var height: CGFloat = 150

    private var maxValue: Double {
        max(data.map { $0.value }.max() ?? 1, 0.0001)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(data) { day in
                    VStack(spacing: 6) {
                        Text(day.value > 0 ? valueFormat(day.value) : "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        GeometryReader { geo in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(day.value > 0 ? color : Theme.track)
                                    .frame(height: barHeight(for: day.value, total: geo.size.height))
                            }
                        }

                        Text(day.weekdayLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: height)
        }
    }

    private func barHeight(for value: Double, total: CGFloat) -> CGFloat {
        guard value > 0 else { return 4 }
        return max(CGFloat(value / maxValue) * total, 6)
    }
}

// MARK: - 카드 컨테이너

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground)
            .cornerRadius(16)
    }
}

// MARK: - 빠른 추가 버튼 (수분)

struct QuickAddButton: View {
    var title: String
    var amount: Int
    var color: Color = Theme.water
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("+\(amount)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 별점 (수면의 질)

struct StarRating: View {
    @Binding var rating: Int       // 1...5
    var color: Color = Theme.sleep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(i <= rating ? color : Theme.track)
                    .onTapGesture { rating = i }
            }
        }
    }
}

/// 읽기 전용 별점 표시
struct StarRatingLabel: View {
    var rating: Int
    var color: Color = Theme.sleep

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundColor(i <= rating ? color : Theme.track)
            }
        }
    }
}

// MARK: - 포맷 헬퍼

enum Format {
    /// ml -> "1.4L" / "350ml"
    static func volume(_ ml: Int) -> String {
        if ml >= 1000 {
            return String(format: "%.1fL", Double(ml) / 1000.0)
        }
        return "\(ml)ml"
    }

    /// 시간(h, Double) -> "7h 10m"
    static func hoursMinutes(_ hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    static func todayLabel() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: Date())
    }
}
