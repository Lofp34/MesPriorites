import SwiftUI

struct HomeView: View {
    @StateObject private var manager = PrioritiesManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var showingDailyCheckIn = false
    @State private var showingWeeklyWrapUp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec niveau utilisateur
                    headerView
                    
                    // Cartes priorités
                    ForEach(Array(manager.priorities.enumerated()), id: \.element.id) { index, priority in
                        NavigationLink(destination: PriorityDetailView(priority: priority)) {
                            PriorityCardView(priority: priority, index: index + 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Quick Actions
                    quickActionsView
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Mes Priorités")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Focus") {
                        // Navigation vers Focus Mode sera gérée par le TabView
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingDailyCheckIn) {
                DailyCheckInView()
            }
            .sheet(isPresented: $showingWeeklyWrapUp) {
                WeeklyWrapUpView()
            }
            .onAppear {
                checkForRituals()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Niveau \(gamificationManager.currentLevel.displayName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Progression semaine : \(Int(manager.weeklyStats.completionRate * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Badge niveau
                ZStack {
                    Circle()
                        .fill(gamificationManager.currentLevel.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(gamificationManager.currentLevel.emoji)
                        .font(.title2)
                }
            }
            
            // Barre de progression hebdomadaire
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * manager.weeklyStats.completionRate, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.5), value: manager.weeklyStats.completionRate)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 16) {
            Text("Actions Rapides")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Check-in",
                    icon: "checkmark.circle",
                    color: .green
                ) {
                    showingDailyCheckIn = true
                }
                
                QuickActionButton(
                    title: "Focus Mode",
                    icon: "timer",
                    color: .orange
                ) {
                    // Déclenché via TabView
                }
                
                QuickActionButton(
                    title: "Nouvelle Tâche",
                    icon: "plus.circle",
                    color: .blue
                ) {
                    // Quick add task to first priority
                    if let firstPriority = manager.priorities.first {
                        let newTask = Task(title: "Nouvelle tâche")
                        manager.addTask(to: firstPriority, task: newTask)
                    }
                }
                
                QuickActionButton(
                    title: "Statistiques",
                    icon: "chart.bar",
                    color: .purple
                ) {
                    // Navigation vers Insights
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func checkForRituals() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Daily Check-in à 8h
        if hour == 8 && !UserDefaults.standard.bool(forKey: "CheckInCompleted-\(calendar.dateComponents([.year, .month, .day], from: now))") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingDailyCheckIn = true
            }
        }
        
        // Weekly Wrap-up le vendredi à 17h
        if calendar.component(.weekday, from: now) == 6 && hour == 17 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingWeeklyWrapUp = true
            }
        }
    }
}

struct PriorityCardView: View {
    let priority: Priority
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Numéro de priorité
            ZStack {
                Circle()
                    .fill(priority.color.swiftUIColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("#\(index)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(priority.color.swiftUIColor)
            }
            
            // Contenu principal
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(priority.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Étoiles importance
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= priority.importance ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                
                // Deadline et urgence
                HStack {
                    Text(priority.deadline, style: .date)
                        .font(.caption)
                        .foregroundColor(priority.urgencyLevel.color)
                    
                    Spacer()
                    
                    Text("\(priority.tasks.filter { $0.isCompleted }.count)/\(priority.tasks.count) tâches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression circulaire
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: priority.progress)
                    .stroke(
                        priority.color.swiftUIColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: priority.progress)
                
                Text("\(Int(priority.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 