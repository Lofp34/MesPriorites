import Foundation
import Combine
import SwiftUI

class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var isActive = false
    @Published var currentPhase: FocusPhase = .work
    @Published var timeRemaining: TimeInterval = 0
    @Published var progress: Double = 0
    
    // Stats journalières
    @Published var todaySessions = 0
    @Published var todayFocusMinutes = 0
    @Published var todayCompletedTasks = 0
    
    private var timer: AnyCancellable?
    private var sessionStartTime: Date?
    
    private let userDefaults = UserDefaults.standard
    private let statsKey = "FocusStats"
    
    private init() {
        loadStats()
        resetToWorkPhase()
    }
    
    // MARK: - Timer Control
    func start() {
        guard !isActive else { return }
        
        isActive = true
        sessionStartTime = Date()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
        
        // Notification pour rester en arrière-plan
        NotificationManager.shared.scheduleTimerNotification(for: currentPhase, duration: timeRemaining)
    }
    
    func pause() {
        isActive = false
        timer?.cancel()
        timer = nil
    }
    
    func reset() {
        pause()
        resetToWorkPhase()
    }
    
    func skip() {
        pause()
        completeCurrentPhase()
    }
    
    // MARK: - Phase Management
    private func tick() {
        timeRemaining -= 1
        updateProgress()
        
        if timeRemaining <= 0 {
            completeCurrentPhase()
        }
    }
    
    private func completeCurrentPhase() {
        // Feedback haptique
        HapticManager.shared.impact(.heavy)
        
        // Stats
        if currentPhase == .work {
            todaySessions += 1
            todayFocusMinutes += Int(currentPhase.duration / 60)
        }
        
        // Passer à la phase suivante
        switch currentPhase {
        case .work:
            currentPhase = todaySessions % 4 == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            currentPhase = .work
        }
        
        timeRemaining = currentPhase.duration
        updateProgress()
        saveStats()
        
        // Notification de fin de phase
        NotificationManager.shared.schedulePhaseCompleteNotification(currentPhase)
        
        // Continuer automatiquement ou s'arrêter selon les préférences
        if UserDefaults.standard.bool(forKey: "AutoContinue") {
            start()
        } else {
            pause()
        }
    }
    
    private func resetToWorkPhase() {
        currentPhase = .work
        timeRemaining = currentPhase.duration
        updateProgress()
    }
    
    private func updateProgress() {
        progress = 1.0 - (timeRemaining / currentPhase.duration)
    }
    
    // MARK: - Task Completion
    func completeTask() {
        todayCompletedTasks += 1
        saveStats()
        
        // Badge accomplissement
        if todayCompletedTasks % 5 == 0 {
            GamificationManager.shared.unlockBadge(.productive)
        }
    }
    
    // MARK: - Computed Properties
    var timeDisplay: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var canReset: Bool {
        return timeRemaining < currentPhase.duration || isActive
    }
    
    // MARK: - Stats Persistence
    private func saveStats() {
        let stats = FocusStats(
            todaySessions: todaySessions,
            todayFocusMinutes: todayFocusMinutes,
            todayCompletedTasks: todayCompletedTasks,
            lastUpdated: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(stats)
            userDefaults.set(data, forKey: statsKey)
        } catch {
            print("Erreur sauvegarde focus stats: \(error)")
        }
    }
    
    private func loadStats() {
        guard let data = userDefaults.data(forKey: statsKey) else {
            resetDailyStats()
            return
        }
        
        do {
            let stats = try JSONDecoder().decode(FocusStats.self, from: data)
            
            // Vérifier si c'est un nouveau jour
            if !Calendar.current.isDate(stats.lastUpdated, inSameDayAs: Date()) {
                resetDailyStats()
            } else {
                todaySessions = stats.todaySessions
                todayFocusMinutes = stats.todayFocusMinutes
                todayCompletedTasks = stats.todayCompletedTasks
            }
        } catch {
            print("Erreur chargement focus stats: \(error)")
            resetDailyStats()
        }
    }
    
    private func resetDailyStats() {
        todaySessions = 0
        todayFocusMinutes = 0
        todayCompletedTasks = 0
        saveStats()
    }
}

// MARK: - Focus Phase
enum FocusPhase: CaseIterable {
    case work
    case shortBreak
    case longBreak
    
    var duration: TimeInterval {
        switch self {
        case .work: return 25 * 60 // 25 minutes
        case .shortBreak: return 5 * 60 // 5 minutes
        case .longBreak: return 15 * 60 // 15 minutes
        }
    }
    
    var displayName: String {
        switch self {
        case .work: return "Travail"
        case .shortBreak: return "Pause courte"
        case .longBreak: return "Pause longue"
        }
    }
    
    var shortName: String {
        switch self {
        case .work: return "Travail"
        case .shortBreak: return "Pause"
        case .longBreak: return "Repos"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .shortBreak: return .green
        case .longBreak: return .purple
        }
    }
    
    var emoji: String {
        switch self {
        case .work: return "🎯"
        case .shortBreak: return "☕"
        case .longBreak: return "🌟"
        }
    }
}

// MARK: - Supporting Models
struct FocusStats: Codable {
    let todaySessions: Int
    let todayFocusMinutes: Int
    let todayCompletedTasks: Int
    let lastUpdated: Date
} 