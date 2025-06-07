import SwiftUI
import Combine

struct FocusModeView: View {
    @StateObject private var focusManager = FocusManager.shared
    @StateObject private var prioritiesManager = PrioritiesManager.shared
    @State private var selectedTask: Task?
    @State private var selectedPriority: Priority?
    @State private var showingTaskSelector = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Minuteur principal
                timerView
                
                // Tâche active
                activeTaskView
                
                // Contrôles
                controlsView
                
                // Sessions aujourd'hui
                sessionStatsView
                
                Spacer()
            }
            .padding()
            .navigationTitle("Mode Focus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sélectionner") {
                        showingTaskSelector = true
                    }
                    .disabled(focusManager.isActive)
                }
            }
            .sheet(isPresented: $showingTaskSelector) {
                TaskSelectorView(
                    selectedTask: $selectedTask,
                    selectedPriority: $selectedPriority
                )
            }
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 20) {
            // Cercle de progression
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: focusManager.progress)
                    .stroke(
                        focusManager.currentPhase.color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: focusManager.progress)
                
                VStack(spacing: 8) {
                    Text(focusManager.timeDisplay)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(focusManager.currentPhase.displayName)
                        .font(.subheadline)
                        .foregroundColor(focusManager.currentPhase.color)
                        .fontWeight(.medium)
                }
            }
            
            // Phase actuelle
            HStack(spacing: 20) {
                ForEach(FocusPhase.allCases, id: \.self) { phase in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(phase == focusManager.currentPhase ? phase.color : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        Text(phase.shortName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var activeTaskView: some View {
        VStack(spacing: 12) {
            Text("Tâche Active")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let task = selectedTask, let priority = selectedPriority {
                HStack(spacing: 12) {
                    Circle()
                        .fill(priority.color.swiftUIColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("#\(prioritiesManager.priorities.firstIndex(where: { $0.id == priority.id }).map { $0 + 1 } ?? 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(priority.color.swiftUIColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        Text(priority.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if focusManager.isActive && focusManager.currentPhase == .work {
                        Button("Terminé") {
                            completeTask()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("Aucune tâche sélectionnée")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Choisir une tâche") {
                        showingTaskSelector = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 20) {
            // Reset
            Button {
                focusManager.reset()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .disabled(!focusManager.canReset)
            
            Spacer()
            
            // Play/Pause principal
            Button {
                if focusManager.isActive {
                    focusManager.pause()
                } else {
                    focusManager.start()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(focusManager.currentPhase.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: focusManager.isActive ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(focusManager.currentPhase.color)
                }
            }
            .disabled(selectedTask == nil)
            
            Spacer()
            
            // Skip
            Button {
                focusManager.skip()
            } label: {
                Image(systemName: "forward.end")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(!focusManager.isActive)
        }
    }
    
    private var sessionStatsView: some View {
        VStack(spacing: 12) {
            Text("Aujourd'hui")
                .font(.headline)
            
            HStack(spacing: 30) {
                StatView(
                    title: "Sessions",
                    value: "\(focusManager.todaySessions)"
                )
                
                StatView(
                    title: "Focus Total",
                    value: "\(focusManager.todayFocusMinutes)min"
                )
                
                StatView(
                    title: "Tâches",
                    value: "\(focusManager.todayCompletedTasks)"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func completeTask() {
        guard let task = selectedTask,
              let priority = selectedPriority else { return }
        
        var completedTask = task
        completedTask.toggle()
        
        prioritiesManager.updateTask(in: priority, task: completedTask)
        focusManager.completeTask()
        
        // Feedback haptique
        HapticManager.shared.impact(.heavy)
        
        // Réinitialiser la sélection
        selectedTask = nil
        selectedPriority = nil
    }
}

struct TaskSelectorView: View {
    @StateObject private var manager = PrioritiesManager.shared
    @Binding var selectedTask: Task?
    @Binding var selectedPriority: Priority?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(manager.priorities) { priority in
                    Section(header: Text(priority.title)) {
                        ForEach(priority.tasks.filter { !$0.isCompleted }) { task in
                            Button {
                                selectedTask = task
                                selectedPriority = priority
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(priority.color.swiftUIColor.opacity(0.2))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text("#\(manager.priorities.firstIndex(where: { $0.id == priority.id }).map { $0 + 1 } ?? 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(priority.color.swiftUIColor)
                                        )
                                    
                                    Text(task.title)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedTask?.id == task.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choisir une tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FocusModeView_Previews: PreviewProvider {
    static var previews: some View {
        FocusModeView()
    }
} 