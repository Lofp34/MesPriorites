import SwiftUI

struct PriorityDetailView: View {
    @StateObject private var manager = PrioritiesManager.shared
    @State private var priority: Priority
    @State private var isEditing = false
    @State private var newTaskTitle = ""
    @State private var showingNewTaskField = false
    @Environment(\.presentationMode) var presentationMode
    
    init(priority: Priority) {
        self._priority = State(initialValue: priority)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header avec progression
                headerView
                
                // Éditeur priorité
                if isEditing {
                    priorityEditorView
                } else {
                    priorityInfoView
                }
                
                // Liste des tâches
                tasksView
                
                // Zone d'ajout rapide
                if showingNewTaskField {
                    newTaskView
                } else {
                    addTaskButton
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(priority.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Sauver" : "Modifier") {
                    if isEditing {
                        manager.updatePriority(priority)
                    }
                    isEditing.toggle()
                }
            }
        }
        .onAppear {
            if let updatedPriority = manager.priorities.first(where: { $0.id == priority.id }) {
                priority = updatedPriority
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: priority.progress)
                    .stroke(
                        priority.color.swiftUIColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: priority.progress)
                
                VStack {
                    Text("\(Int(priority.progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Terminé")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats rapides
            HStack(spacing: 30) {
                StatView(
                    title: "Tâches",
                    value: "\(priority.tasks.filter { $0.isCompleted }.count)/\(priority.tasks.count)"
                )
                
                StatView(
                    title: "Importance",
                    value: String(repeating: "⭐", count: priority.importance)
                )
                
                StatView(
                    title: "Deadline",
                    value: priority.deadline.formatted(.dateTime.day().month(.abbreviated))
                )
            }
        }
        .padding()
        .background(priority.color.swiftUIColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var priorityInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Détails de la priorité")
                .font(.headline)
            
            HStack {
                Text("Couleur:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(priority.color.swiftUIColor)
                    .frame(width: 20, height: 20)
                
                Text(priority.color.displayName)
                    .font(.subheadline)
            }
            
            HStack {
                Text("Urgence:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(urgencyText)
                    .font(.subheadline)
                    .foregroundColor(priority.urgencyLevel.color)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var priorityEditorView: some View {
        VStack(spacing: 16) {
            Text("Modifier la priorité")
                .font(.headline)
            
            TextField("Titre (max 60 caractères)", text: $priority.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: priority.title) { newValue in
                    if newValue.count > 60 {
                        priority.title = String(newValue.prefix(60))
                    }
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Importance: \(priority.importance) étoile\(priority.importance > 1 ? "s" : "")")
                    .font(.subheadline)
                
                Slider(value: Binding(
                    get: { Double(priority.importance) },
                    set: { priority.importance = Int($0) }
                ), in: 1...5, step: 1)
                .tint(priority.color.swiftUIColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Couleur")
                    .font(.subheadline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                    ForEach(PriorityColor.allCases, id: \.self) { color in
                        Button {
                            priority.color = color
                        } label: {
                            Circle()
                                .fill(color.swiftUIColor)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: priority.color == color ? 2 : 0)
                                )
                        }
                    }
                }
            }
            
            DatePicker("Date limite", selection: $priority.deadline, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tâches (\(priority.tasks.count))")
                    .font(.headline)
                
                Spacer()
                
                if !priority.tasks.isEmpty {
                    Text("\(priority.tasks.filter { $0.isCompleted }.count) terminées")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if priority.tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("Aucune tâche pour le moment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Ajoutez votre première tâche pour commencer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
            } else {
                ForEach(priority.tasks.sorted(by: { $0.order < $1.order })) { task in
                    TaskRowView(
                        task: task,
                        priority: priority,
                        onToggle: { toggledTask in
                            updateTask(toggledTask)
                        },
                        onDelete: { taskToDelete in
                            deleteTask(taskToDelete)
                        }
                    )
                }
                .onMove(perform: moveTask)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var newTaskView: some View {
        VStack(spacing: 12) {
            TextField("Nouvelle tâche...", text: $newTaskTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                    addNewTask()
                }
            
            HStack(spacing: 12) {
                Button("Annuler") {
                    newTaskTitle = ""
                    showingNewTaskField = false
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Ajouter") {
                    addNewTask()
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .foregroundColor(.blue)
                .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var addTaskButton: some View {
        Button {
            showingNewTaskField = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Ajouter une tâche")
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var urgencyText: String {
        switch priority.urgencyLevel {
        case .normal: return "Normale"
        case .high: return "Élevée"
        case .critical: return "Critique"
        case .overdue: return "En retard"
        }
    }
    
    private func addNewTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let task = Task(title: newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines))
        manager.addTask(to: priority, task: task)
        
        newTaskTitle = ""
        showingNewTaskField = false
        
        // Mettre à jour la priorité locale
        if let updatedPriority = manager.priorities.first(where: { $0.id == priority.id }) {
            priority = updatedPriority
        }
    }
    
    private func updateTask(_ task: Task) {
        manager.updateTask(in: priority, task: task)
        
        // Mettre à jour la priorité locale
        if let updatedPriority = manager.priorities.first(where: { $0.id == priority.id }) {
            priority = updatedPriority
        }
    }
    
    private func deleteTask(_ task: Task) {
        manager.deleteTask(from: priority, task: task)
        
        // Mettre à jour la priorité locale
        if let updatedPriority = manager.priorities.first(where: { $0.id == priority.id }) {
            priority = updatedPriority
        }
    }
    
    private func moveTask(from source: IndexSet, to destination: Int) {
        manager.reorderTasks(in: priority, from: source, to: destination)
        
        // Mettre à jour la priorité locale
        if let updatedPriority = manager.priorities.first(where: { $0.id == priority.id }) {
            priority = updatedPriority
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TaskRowView: View {
    @State private var task: Task
    let priority: Priority
    let onToggle: (Task) -> Void
    let onDelete: (Task) -> Void
    
    init(task: Task, priority: Priority, onToggle: @escaping (Task) -> Void, onDelete: @escaping (Task) -> Void) {
        self._task = State(initialValue: task)
        self.priority = priority
        self.onToggle = onToggle
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                task.toggle()
                onToggle(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? priority.color.swiftUIColor : .gray)
                    .font(.title3)
            }
            
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            if task.isCompleted, let completedAt = task.completedAt {
                Text(completedAt.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Supprimer", role: .destructive) {
                onDelete(task)
            }
        }
    }
}

struct PriorityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PriorityDetailView(priority: Priority.sampleData[0])
        }
    }
} 