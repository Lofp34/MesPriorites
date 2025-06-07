import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission Request
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications autorisées")
            } else if let error = error {
                print("Erreur permission notifications: \(error)")
            }
        }
    }
    
    // MARK: - Daily Check-in
    func scheduleDailyCheckIn() {
        let content = UNMutableNotificationContent()
        content.title = "🌅 Daily Check-in"
        content.body = "Comment avez-vous progressé sur vos priorités hier ?"
        content.sound = .default
        
        // Tous les jours à 8h
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-checkin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur programmation check-in: \(error)")
            }
        }
    }
    
    // MARK: - Weekly Wrap-up
    func scheduleWeeklyWrapUp() {
        let content = UNMutableNotificationContent()
        content.title = "📊 Récap Hebdomadaire"
        content.body = "Vendredi 17h : il est temps de faire le bilan de votre semaine !"
        content.sound = .default
        
        // Tous les vendredis à 17h
        var dateComponents = DateComponents()
        dateComponents.weekday = 6 // Vendredi
        dateComponents.hour = 17
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-wrapup", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur programmation wrap-up: \(error)")
            }
        }
    }
    
    // MARK: - Focus Timer Notifications
    func scheduleTimerNotification(for phase: FocusPhase, duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(phase.displayName)"
        content.body = "Session de \(Int(duration/60)) minutes démarrée"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: "timer-\(phase.rawValue)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur notification timer: \(error)")
            }
        }
    }
    
    func schedulePhaseCompleteNotification(_ nextPhase: FocusPhase) {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Phase terminée !"
        content.body = "Prêt pour \(nextPhase.displayName.lowercased()) ? \(nextPhase.emoji)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "phase-complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur notification phase: \(error)")
            }
        }
    }
    
    // MARK: - Gamification Notifications
    func scheduleLevelUpNotification(_ level: UserLevel) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Nouveau niveau !"
        content.body = "Félicitations ! Vous êtes maintenant \(level.displayName) \(level.emoji)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "level-up-\(level.rawValue)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur notification level-up: \(error)")
            }
        }
    }
    
    func scheduleBadgeUnlockedNotification(_ badge: Badge) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Badge débloqué !"
        content.body = "\(badge.emoji) \(badge.title) : \(badge.description)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "badge-\(badge.rawValue)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur notification badge: \(error)")
            }
        }
    }
    
    // MARK: - Task Reminders
    func scheduleTaskReminder(for task: Task, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "📝 Rappel de tâche"
        content.body = task.title
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date), repeats: false)
        let request = UNNotificationRequest(identifier: "task-\(task.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur rappel tâche: \(error)")
            }
        }
    }
    
    // MARK: - Priority Deadlines
    func schedulePriorityDeadlineReminder(for priority: Priority) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Deadline approche"
        content.body = "\(priority.title) - \(priority.deadline.formatted(.dateTime.day().month()))"
        content.sound = .default
        
        // Rappel 24h avant la deadline
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: priority.deadline) ?? priority.deadline
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate), repeats: false)
        let request = UNNotificationRequest(identifier: "deadline-\(priority.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur rappel deadline: \(error)")
            }
        }
    }
    
    // MARK: - Utility
    func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 