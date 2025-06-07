import Foundation
import Combine

class PrioritiesManager: ObservableObject {
    static let shared = PrioritiesManager()
    
    @Published var priorities: [Priority] = []
    @Published var weeklyStats: WeeklyStats = WeeklyStats()
    
    private let userDefaults = UserDefaults.standard
    private let prioritiesKey = "SavedPriorities"
    private let statsKey = "WeeklyStats"
    
    private init() {
        loadPriorities()
        loadWeeklyStats()
    }
    
    // MARK: - Data Loading
    func loadInitialData() {
        if priorities.isEmpty {
            priorities = Priority.sampleData
            savePriorities()
        }
    }
    
    func loadFromJSON(_ jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        
        do {
            let jsonPriorities = try JSONDecoder().decode(PrioritiesJSON.self, from: jsonData)
            
            // Convertir les données JSON en modèle Priority
            priorities = jsonPriorities.priorites.prefix(3).enumerated().map { index, jsonPriority in
                let deadline = ISO8601DateFormatter().date(from: jsonPriority.deadline) ?? 
                              Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
                
                let tasks = jsonPriority.taches.enumerated().map { taskIndex, jsonTask in
                    Task(title: jsonTask.titre, isCompleted: jsonTask.done, order: taskIndex)
                }
                
                return Priority(
                    title: jsonPriority.titre,
                    importance: jsonPriority.importance,
                    deadline: deadline,
                    color: PriorityColor.allCases[index % PriorityColor.allCases.count],
                    tasks: tasks
                )
            }
            
            savePriorities()
        } catch {
            print("Erreur lors du chargement JSON: \(error)")
            loadInitialData() // Fallback vers les données par défaut
        }
    }
    
    // MARK: - Priority Management
    func addPriority(_ priority: Priority) {
        if priorities.count < 3 {
            priorities.append(priority)
            savePriorities()
        }
    }
    
    func updatePriority(_ priority: Priority) {
        if let index = priorities.firstIndex(where: { $0.id == priority.id }) {
            priorities[index] = priority
            savePriorities()
            updateWeeklyStats()
        }
    }
    
    func deletePriority(_ priority: Priority) {
        priorities.removeAll { $0.id == priority.id }
        savePriorities()
    }
    
    // MARK: - Task Management
    func addTask(to priority: Priority, task: Task) {
        if let index = priorities.firstIndex(where: { $0.id == priority.id }) {
            var updatedTask = task
            updatedTask.order = priorities[index].tasks.count
            priorities[index].tasks.append(updatedTask)
            savePriorities()
        }
    }
    
    func updateTask(in priority: Priority, task: Task) {
        if let priorityIndex = priorities.firstIndex(where: { $0.id == priority.id }),
           let taskIndex = priorities[priorityIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            priorities[priorityIndex].tasks[taskIndex] = task
            savePriorities()
            updateWeeklyStats()
            
            // Feedback haptique pour validation tâche
            if task.isCompleted {
                HapticManager.shared.impact(.medium)
            }
        }
    }
    
    func deleteTask(from priority: Priority, task: Task) {
        if let priorityIndex = priorities.firstIndex(where: { $0.id == priority.id }) {
            priorities[priorityIndex].tasks.removeAll { $0.id == task.id }
            savePriorities()
        }
    }
    
    func reorderTasks(in priority: Priority, from source: IndexSet, to destination: Int) {
        if let priorityIndex = priorities.firstIndex(where: { $0.id == priority.id }) {
            priorities[priorityIndex].tasks.move(fromOffsets: source, toOffset: destination)
            
            // Réassigner les ordres
            for (index, task) in priorities[priorityIndex].tasks.enumerated() {
                priorities[priorityIndex].tasks[index].order = index
            }
            
            savePriorities()
        }
    }
    
    // MARK: - Weekly Statistics
    func updateWeeklyStats() {
        let totalTasks = priorities.flatMap { $0.tasks }.count
        let completedTasks = priorities.flatMap { $0.tasks }.filter { $0.isCompleted }.count
        let completedPriorities = priorities.filter { $0.isCompleted }.count
        
        weeklyStats.totalTasks = totalTasks
        weeklyStats.completedTasks = completedTasks
        weeklyStats.completedPriorities = completedPriorities
        weeklyStats.lastUpdated = Date()
        
        // Vérifier si l'utilisateur mérite un nouveau niveau
        if completedPriorities == 3 {
            GamificationManager.shared.unlockBadge(.hatTrick)
        }
        
        saveWeeklyStats()
    }
    
    func resetWeeklyData() {
        // Réinitialiser les priorités pour une nouvelle semaine
        for index in priorities.indices {
            for taskIndex in priorities[index].tasks.indices {
                priorities[index].tasks[taskIndex].isCompleted = false
                priorities[index].tasks[taskIndex].completedAt = nil
            }
        }
        
        weeklyStats = WeeklyStats()
        savePriorities()
        saveWeeklyStats()
    }
    
    // MARK: - Persistence
    private func savePriorities() {
        do {
            let data = try JSONEncoder().encode(priorities)
            userDefaults.set(data, forKey: prioritiesKey)
        } catch {
            print("Erreur sauvegarde priorities: \(error)")
        }
    }
    
    private func loadPriorities() {
        guard let data = userDefaults.data(forKey: prioritiesKey) else { return }
        
        do {
            priorities = try JSONDecoder().decode([Priority].self, from: data)
        } catch {
            print("Erreur chargement priorities: \(error)")
        }
    }
    
    private func saveWeeklyStats() {
        do {
            let data = try JSONEncoder().encode(weeklyStats)
            userDefaults.set(data, forKey: statsKey)
        } catch {
            print("Erreur sauvegarde stats: \(error)")
        }
    }
    
    private func loadWeeklyStats() {
        guard let data = userDefaults.data(forKey: statsKey) else { return }
        
        do {
            weeklyStats = try JSONDecoder().decode(WeeklyStats.self, from: data)
        } catch {
            print("Erreur chargement stats: \(error)")
        }
    }
}

// MARK: - Supporting Models
struct WeeklyStats: Codable {
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var completedPriorities: Int = 0
    var lastUpdated: Date = Date()
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

struct PrioritiesJSON: Codable {
    let priorites: [PriorityJSON]
}

struct PriorityJSON: Codable {
    let titre: String
    let importance: Int
    let deadline: String
    let taches: [TaskJSON]
}

struct TaskJSON: Codable {
    let titre: String
    let done: Bool
} 