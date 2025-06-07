import Foundation
import SwiftUI

// MARK: - Priority Model
struct Priority: Identifiable, Codable {
    let id = UUID()
    var title: String
    var importance: Int // 1-5 étoiles
    var deadline: Date
    var color: PriorityColor
    var tasks: [Task]
    var createdAt: Date
    var completedAt: Date?
    
    init(title: String, importance: Int = 3, deadline: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(), color: PriorityColor = .blue, tasks: [Task] = []) {
        self.title = title
        self.importance = importance
        self.deadline = deadline
        self.color = color
        self.tasks = tasks
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
    
    var isCompleted: Bool {
        return progress >= 1.0 && !tasks.isEmpty
    }
    
    var isOverdue: Bool {
        return Date() > deadline && !isCompleted
    }
    
    var urgencyLevel: UrgencyLevel {
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if isOverdue {
            return .overdue
        } else if daysUntilDeadline <= 1 {
            return .critical
        } else if daysUntilDeadline <= 3 {
            return .high
        } else {
            return .normal
        }
    }
}

// MARK: - Task Model
struct Task: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var reminderDate: Date?
    var order: Int
    
    init(title: String, isCompleted: Bool = false, order: Int = 0) {
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
    }
    
    mutating func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

// MARK: - Supporting Enums
enum PriorityColor: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    
    var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return "Bleu"
        case .green: return "Vert"
        case .orange: return "Orange"
        case .red: return "Rouge"
        case .purple: return "Violet"
        case .pink: return "Rose"
        }
    }
}

enum UrgencyLevel {
    case normal, high, critical, overdue
    
    var color: Color {
        switch self {
        case .normal: return .primary
        case .high: return .orange
        case .critical: return .red
        case .overdue: return Color(red: 0.8, green: 0.1, blue: 0.1)
        }
    }
}

// MARK: - Sample Data
extension Priority {
    static let sampleData: [Priority] = [
        Priority(
            title: "Automatiser facturation & paiements",
            importance: 5,
            deadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            color: .red,
            tasks: [
                Task(title: "Créer onglets 'Factures/Payées' dans Drive", order: 0),
                Task(title: "Configurer Zapier → facture ⇒ carte Trello", order: 1),
                Task(title: "Tester le workflow complet", order: 2),
                Task(title: "Former l'équipe sur le nouveau process", order: 3)
            ]
        ),
        Priority(
            title: "Booster prospection clients",
            importance: 4,
            deadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            color: .blue,
            tasks: [
                Task(title: "Écrire script 1er épisode série vidéo", order: 0),
                Task(title: "Tourner vidéo 'Vendre ×10 avec l'IA'", order: 1),
                Task(title: "Publier sur LinkedIn + YouTube", order: 2),
                Task(title: "Finaliser carrousel logos site vitrine", order: 3),
                Task(title: "Ajouter CTA 'Contactez-nous'", order: 4)
            ]
        ),
        Priority(
            title: "Soigner sommeil & bien-être",
            importance: 4,
            deadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            color: .green,
            tasks: [
                Task(title: "Prendre mélatonine avant 22h30", order: 0),
                Task(title: "Session jogging/rando ce week-end", order: 1),
                Task(title: "Temps dédié famille (Albane, France-Pascal)", order: 2),
                Task(title: "Alléger planning vendredi après-midi", order: 3)
            ]
        )
    ]
} 