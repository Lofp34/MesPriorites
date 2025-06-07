import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Selection Feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Convenience Methods
    func taskCompleted() {
        impact(.medium)
    }
    
    func priorityCompleted() {
        impact(.heavy)
    }
    
    func badgeUnlocked() {
        notification(.success)
    }
    
    func levelUp() {
        // Séquence d'impacts pour célébrer
        DispatchQueue.main.async {
            self.impact(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impact(.medium)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.impact(.heavy)
                }
            }
        }
    }
    
    func error() {
        notification(.error)
    }
    
    func warning() {
        notification(.warning)
    }
} 