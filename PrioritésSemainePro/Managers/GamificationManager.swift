import Foundation
import SwiftUI

class GamificationManager: ObservableObject {
    static let shared = GamificationManager()
    
    @Published var currentLevel: UserLevel = .rookie
    @Published var experiencePoints: Int = 0
    @Published var unlockedBadges: Set<Badge> = []
    @Published var weeklyStreak: Int = 0
    @Published var totalCompletedWeeks: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let gamificationKey = "GamificationData"
    
    private init() {
        loadGamificationData()
        updateLevel()
    }
    
    // MARK: - Experience & Levels
    func addExperience(_ points: Int) {
        experiencePoints += points
        updateLevel()
        saveGamificationData()
    }
    
    private func updateLevel() {
        let newLevel = UserLevel.levelForExperience(experiencePoints)
        if newLevel != currentLevel {
            currentLevel = newLevel
            // Notification de niveau up
            NotificationManager.shared.scheduleLevelUpNotification(newLevel)
        }
    }
    
    // MARK: - Badge System
    func unlockBadge(_ badge: Badge) {
        guard !unlockedBadges.contains(badge) else { return }
        
        unlockedBadges.insert(badge)
        addExperience(badge.experienceReward)
        
        // Feedback et notification
        HapticManager.shared.impact(.heavy)
        NotificationManager.shared.scheduleBadgeUnlockedNotification(badge)
        
        saveGamificationData()
    }
    
    func checkBadgeProgress() {
        let prioritiesManager = PrioritiesManager.shared
        
        // Badge Hat-trick (3 priorités complètes dans la semaine)
        let completedPriorities = prioritiesManager.priorities.filter { $0.isCompleted }.count
        if completedPriorities >= 3 {
            unlockBadge(.hatTrick)
        }
        
        // Badge Early Bird (check-in avant 9h)
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 9 && UserDefaults.standard.bool(forKey: "CheckInCompleted-\(Date())") {
            unlockBadge(.earlyBird)
        }
        
        // Badge Productive (5+ tâches terminées en Focus Mode)
        let focusManager = FocusManager.shared
        if focusManager.todayCompletedTasks >= 5 {
            unlockBadge(.productive)
        }
        
        // Badge Consistent (streak de 7 semaines)
        if weeklyStreak >= 7 {
            unlockBadge(.consistent)
        }
    }
    
    // MARK: - Weekly Progress
    func completeWeek(completionRate: Double) {
        totalCompletedWeeks += 1
        
        if completionRate >= 0.8 { // 80% ou plus
            weeklyStreak += 1
            addExperience(100) // Bonus semaine réussie
        } else {
            weeklyStreak = 0 // Reset du streak
        }
        
        checkBadgeProgress()
        saveGamificationData()
    }
    
    // MARK: - Achievements Overview
    var progressToNextLevel: Double {
        let currentLevelXP = UserLevel.experienceForLevel(currentLevel)
        let nextLevelXP = UserLevel.experienceForLevel(currentLevel.next)
        let progress = experiencePoints - currentLevelXP
        let required = nextLevelXP - currentLevelXP
        
        guard required > 0 else { return 1.0 }
        return Double(progress) / Double(required)
    }
    
    var experienceToNextLevel: Int {
        return UserLevel.experienceForLevel(currentLevel.next) - experiencePoints
    }
    
    // MARK: - Persistence
    private func saveGamificationData() {
        let data = GamificationData(
            currentLevel: currentLevel,
            experiencePoints: experiencePoints,
            unlockedBadges: Array(unlockedBadges),
            weeklyStreak: weeklyStreak,
            totalCompletedWeeks: totalCompletedWeeks
        )
        
        do {
            let encoded = try JSONEncoder().encode(data)
            userDefaults.set(encoded, forKey: gamificationKey)
        } catch {
            print("Erreur sauvegarde gamification: \(error)")
        }
    }
    
    private func loadGamificationData() {
        guard let data = userDefaults.data(forKey: gamificationKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode(GamificationData.self, from: data)
            currentLevel = decoded.currentLevel
            experiencePoints = decoded.experiencePoints
            unlockedBadges = Set(decoded.unlockedBadges)
            weeklyStreak = decoded.weeklyStreak
            totalCompletedWeeks = decoded.totalCompletedWeeks
        } catch {
            print("Erreur chargement gamification: \(error)")
        }
    }
}

// MARK: - User Levels
enum UserLevel: String, CaseIterable, Codable {
    case rookie = "rookie"
    case explorer = "explorer"
    case achiever = "achiever"
    case expert = "expert"
    case master = "master"
    case wizard = "wizard"
    
    var displayName: String {
        switch self {
        case .rookie: return "Rookie"
        case .explorer: return "Explorer"
        case .achiever: return "Achiever"
        case .expert: return "Expert"
        case .master: return "Master"
        case .wizard: return "Wizard"
        }
    }
    
    var emoji: String {
        switch self {
        case .rookie: return "🌱"
        case .explorer: return "🔍"
        case .achiever: return "🎯"
        case .expert: return "⭐"
        case .master: return "🏆"
        case .wizard: return "🧙‍♂️"
        }
    }
    
    var color: Color {
        switch self {
        case .rookie: return .green
        case .explorer: return .blue
        case .achiever: return .orange
        case .expert: return .purple
        case .master: return .red
        case .wizard: return .pink
        }
    }
    
    var next: UserLevel {
        switch self {
        case .rookie: return .explorer
        case .explorer: return .achiever
        case .achiever: return .expert
        case .expert: return .master
        case .master: return .wizard
        case .wizard: return .wizard // Max level
        }
    }
    
    static func levelForExperience(_ xp: Int) -> UserLevel {
        if xp >= 5000 { return .wizard }
        if xp >= 2500 { return .master }
        if xp >= 1200 { return .expert }
        if xp >= 600 { return .achiever }
        if xp >= 200 { return .explorer }
        return .rookie
    }
    
    static func experienceForLevel(_ level: UserLevel) -> Int {
        switch level {
        case .rookie: return 0
        case .explorer: return 200
        case .achiever: return 600
        case .expert: return 1200
        case .master: return 2500
        case .wizard: return 5000
        }
    }
}

// MARK: - Badges
enum Badge: String, CaseIterable, Codable, Hashable {
    case hatTrick = "hat_trick"
    case earlyBird = "early_bird"
    case productive = "productive"
    case consistent = "consistent"
    case perfectWeek = "perfect_week"
    case speedster = "speedster"
    
    var title: String {
        switch self {
        case .hatTrick: return "Hat-trick"
        case .earlyBird: return "Early Bird"
        case .productive: return "Productif"
        case .consistent: return "Consistant"
        case .perfectWeek: return "Semaine Parfaite"
        case .speedster: return "Speedster"
        }
    }
    
    var description: String {
        switch self {
        case .hatTrick: return "3 priorités complètes dans la semaine"
        case .earlyBird: return "Check-in avant 9h du matin"
        case .productive: return "5+ tâches terminées en Focus Mode"
        case .consistent: return "7 semaines consécutives réussies"
        case .perfectWeek: return "100% de complétion hebdomadaire"
        case .speedster: return "10 tâches terminées en une journée"
        }
    }
    
    var emoji: String {
        switch self {
        case .hatTrick: return "🎯"
        case .earlyBird: return "🌅"
        case .productive: return "⚡"
        case .consistent: return "🔥"
        case .perfectWeek: return "✨"
        case .speedster: return "🚀"
        }
    }
    
    var experienceReward: Int {
        switch self {
        case .hatTrick: return 50
        case .earlyBird: return 25
        case .productive: return 30
        case .consistent: return 100
        case .perfectWeek: return 75
        case .speedster: return 40
        }
    }
    
    var rarity: BadgeRarity {
        switch self {
        case .hatTrick: return .common
        case .earlyBird: return .common
        case .productive: return .uncommon
        case .consistent: return .rare
        case .perfectWeek: return .epic
        case .speedster: return .uncommon
        }
    }
}

enum BadgeRarity {
    case common, uncommon, rare, epic
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }
}

// MARK: - Supporting Models
struct GamificationData: Codable {
    let currentLevel: UserLevel
    let experiencePoints: Int
    let unlockedBadges: [Badge]
    let weeklyStreak: Int
    let totalCompletedWeeks: Int
} 