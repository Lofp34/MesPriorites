import SwiftUI
import Charts

struct InsightsView: View {
    @StateObject private var prioritiesManager = PrioritiesManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var focusManager = FocusManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    timeRangePicker
                    
                    // Overview Cards
                    overviewCards
                    
                    // Progress Chart
                    progressChart
                    
                    // Heatmap
                    weeklyHeatmap
                    
                    // Focus Stats
                    focusStatsView
                    
                    // Gamification Progress
                    gamificationProgress
                    
                    // Achievement Gallery
                    achievementGallery
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var timeRangePicker: some View {
        Picker("Période", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Complétion",
                value: "\(Int(prioritiesManager.weeklyStats.completionRate * 100))%",
                icon: "target",
                color: .blue,
                trend: .up
            )
            
            MetricCard(
                title: "Priorités OK",
                value: "\(prioritiesManager.weeklyStats.completedPriorities)/3",
                icon: "checkmark.circle",
                color: .green,
                trend: .stable
            )
            
            MetricCard(
                title: "Focus Today",
                value: "\(focusManager.todayFocusMinutes)min",
                icon: "timer",
                color: .orange,
                trend: .up
            )
            
            MetricCard(
                title: "Niveau",
                value: gamificationManager.currentLevel.displayName,
                icon: "star",
                color: gamificationManager.currentLevel.color,
                trend: .up
            )
        }
    }
    
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progression Hebdomadaire")
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                
                // Chart placeholder - en attendant iOS 16 Charts
                VStack {
                    HStack {
                        ForEach(0..<7) { day in
                            VStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(Double.random(in: 0.3...1.0)))
                                    .frame(width: 20, height: CGFloat.random(in: 40...120))
                                
                                Text(dayNames[day])
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var weeklyHeatmap: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heatmap d'Activité")
                .font(.headline)
            
            VStack(spacing: 8) {
                // Dernières 4 semaines
                ForEach(0..<4) { week in
                    HStack(spacing: 4) {
                        Text("S\(4-week)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        ForEach(0..<7) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatmapColor(for: week, day: day))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                
                // Légende
                HStack {
                    Text("Moins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { intensity in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.green.opacity(0.2 + Double(intensity) * 0.2))
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Text("Plus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var focusStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Mode - Aujourd'hui")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(focusManager.todaySessions)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(focusManager.todayFocusMinutes)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(focusManager.todayCompletedTasks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Tâches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Visual representation
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: min(1.0, Double(focusManager.todaySessions) / 8.0))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(min(100, Double(focusManager.todaySessions) * 12.5)))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var gamificationProgress: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progression Niveau")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Niveau actuel
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(gamificationManager.currentLevel.color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text(gamificationManager.currentLevel.emoji)
                            .font(.title2)
                    }
                    
                    Text(gamificationManager.currentLevel.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("XP: \(gamificationManager.experiencePoints)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("-\(gamificationManager.experienceToNextLevel) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(gamificationManager.currentLevel.color)
                                .frame(width: geometry.size.width * gamificationManager.progressToNextLevel, height: 8)
                                .cornerRadius(4)
                                .animation(.easeInOut(duration: 0.5), value: gamificationManager.progressToNextLevel)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("Prochain niveau:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(gamificationManager.currentLevel.next.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(gamificationManager.currentLevel.next.color)
                        
                        Text(gamificationManager.currentLevel.next.emoji)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var achievementGallery: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                
                Spacer()
                
                Text("\(gamificationManager.unlockedBadges.count)/\(Badge.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Badge.allCases, id: \.self) { badge in
                    BadgeView(
                        badge: badge,
                        isUnlocked: gamificationManager.unlockedBadges.contains(badge)
                    )
                }
            }
        }
    }
    
    private let dayNames = ["L", "M", "M", "J", "V", "S", "D"]
    
    private func heatmapColor(for week: Int, day: Int) -> Color {
        // Simulation de données d'activité
        let intensity = Double.random(in: 0...1)
        return Color.green.opacity(0.2 + intensity * 0.8)
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Image(systemName: trend.iconName)
                    .foregroundColor(trend.color)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BadgeView: View {
    let badge: Badge
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? badge.rarity.color.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(badge.emoji)
                    .font(.title3)
                    .opacity(isUnlocked ? 1.0 : 0.3)
            }
            
            Text(badge.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .background(isUnlocked ? Color(.systemBackground) : Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isUnlocked ? badge.rarity.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Supporting Types
enum TimeRange: CaseIterable {
    case week, month, quarter
    
    var displayName: String {
        switch self {
        case .week: return "Semaine"
        case .month: return "Mois"
        case .quarter: return "Trimestre"
        }
    }
}

enum Trend {
    case up, down, stable
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .orange
        }
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
    }
} 