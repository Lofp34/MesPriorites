import SwiftUI

struct WeeklyWrapUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var prioritiesManager = PrioritiesManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var focusManager = FocusManager.shared
    
    @State private var showConfetti = false
    @State private var showNewWeekSetup = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec score global
                    weeklyScoreHeader
                    
                    // Détail des priorités
                    prioritiesBreakdown
                    
                    // Stats de la semaine
                    weeklyStats
                    
                    // Insights et améliorations
                    weeklyInsights
                    
                    // Actions pour la semaine suivante
                    nextWeekActions
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Récap Semaine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if weeklyCompletionRate >= 0.8 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showConfetti = true
                        HapticManager.shared.levelUp()
                    }
                }
            }
            .overlay(
                ConfettiView()
                    .opacity(showConfetti ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showConfetti)
            )
            .sheet(isPresented: $showNewWeekSetup) {
                NewWeekSetupView()
            }
        }
    }
    
    private var weeklyScoreHeader: some View {
        VStack(spacing: 20) {
            // Score principal
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: weeklyCompletionRate)
                    .stroke(
                        weeklyCompletionRate >= 0.8 ? Color.green :
                        weeklyCompletionRate >= 0.6 ? Color.orange : Color.red,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: weeklyCompletionRate)
                
                VStack(spacing: 4) {
                    Text("\(Int(weeklyCompletionRate * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Complétion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Message de félicitations ou encouragement
            VStack(spacing: 8) {
                Text(weeklyMessage.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(weeklyMessage.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Badge de performance
            if weeklyCompletionRate >= 0.8 {
                performanceBadge
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
    
    private var performanceBadge: some View {
        HStack(spacing: 8) {
            Text("🏆")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Excellente semaine !")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("+\(weeklyBonusXP) XP bonus")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var prioritiesBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Détail des Priorités")
                .font(.headline)
            
            ForEach(Array(prioritiesManager.priorities.enumerated()), id: \.element.id) { index, priority in
                PriorityResultCard(priority: priority, index: index + 1)
            }
        }
    }
    
    private var weeklyStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiques de la Semaine")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Tâches Terminées",
                    value: "\(completedTasksCount)",
                    subtitle: "sur \(totalTasksCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Sessions Focus",
                    value: "\(weeklyFocusSessions)",
                    subtitle: "\(weeklyFocusMinutes) min total",
                    icon: "timer.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Check-ins",
                    value: "\(weeklyCheckIns)",
                    subtitle: "sur 7 jours",
                    icon: "calendar.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Niveau Actuel",
                    value: gamificationManager.currentLevel.displayName,
                    subtitle: "\(gamificationManager.experiencePoints) XP",
                    icon: "star.circle.fill",
                    color: gamificationManager.currentLevel.color
                )
            }
        }
    }
    
    private var weeklyInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Améliorations")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(insights, id: \.title) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
    
    private var nextWeekActions: some View {
        VStack(spacing: 16) {
            Button {
                completeWeekAndSetupNext()
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                    
                    Text("Préparer la Semaine Suivante")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button {
                resetCurrentWeek()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.title3)
                    
                    Text("Recommencer cette Semaine")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var weeklyCompletionRate: Double {
        return prioritiesManager.weeklyStats.completionRate
    }
    
    private var completedTasksCount: Int {
        return prioritiesManager.priorities.flatMap { $0.tasks }.filter { $0.isCompleted }.count
    }
    
    private var totalTasksCount: Int {
        return prioritiesManager.priorities.flatMap { $0.tasks }.count
    }
    
    private var weeklyFocusSessions: Int {
        return focusManager.todaySessions * 7 // Approximation
    }
    
    private var weeklyFocusMinutes: Int {
        return focusManager.todayFocusMinutes * 7 // Approximation
    }
    
    private var weeklyCheckIns: Int {
        return 5 // Simulé pour la démo
    }
    
    private var weeklyBonusXP: Int {
        return weeklyCompletionRate >= 1.0 ? 100 :
               weeklyCompletionRate >= 0.8 ? 75 : 0
    }
    
    private var weeklyMessage: (title: String, subtitle: String) {
        if weeklyCompletionRate >= 1.0 {
            return ("🎉 Semaine Parfaite !", "Toutes vos priorités sont accomplies")
        } else if weeklyCompletionRate >= 0.8 {
            return ("🌟 Excellente Semaine !", "Vous avez accompli la plupart de vos objectifs")
        } else if weeklyCompletionRate >= 0.6 {
            return ("💪 Bon Travail !", "Vous êtes sur la bonne voie")
        } else {
            return ("🎯 La Prochaine Sera Mieux !", "Chaque semaine est une nouvelle chance")
        }
    }
    
    private var insights: [WeeklyInsight] {
        var results: [WeeklyInsight] = []
        
        // Insight sur les priorités
        let completedPriorities = prioritiesManager.priorities.filter { $0.isCompleted }.count
        if completedPriorities == 3 {
            results.append(WeeklyInsight(
                title: "🎯 Toutes les priorités accomplies",
                description: "Fantastique ! Vous maîtrisez parfaitement votre planning.",
                type: .success
            ))
        } else if completedPriorities >= 2 {
            results.append(WeeklyInsight(
                title: "✅ Priorités principales terminées",
                description: "Très bien ! Concentrez-vous sur la dernière priorité.",
                type: .good
            ))
        } else {
            results.append(WeeklyInsight(
                title: "🔄 Revoir la planification",
                description: "Essayez de diviser vos priorités en tâches plus petites.",
                type: .improvement
            ))
        }
        
        // Insight sur le focus
        if weeklyFocusSessions >= 10 {
            results.append(WeeklyInsight(
                title: "⏱️ Maître du Focus",
                description: "Excellente utilisation du mode Focus ! Continuez ainsi.",
                type: .success
            ))
        }
        
        return results
    }
    
    // MARK: - Actions
    private func completeWeekAndSetupNext() {
        // Gamification
        gamificationManager.completeWeek(completionRate: weeklyCompletionRate)
        
        if weeklyCompletionRate >= 0.8 {
            gamificationManager.addExperience(weeklyBonusXP)
        }
        
        // Feedback
        HapticManager.shared.notification(.success)
        
        // Préparer nouvelle semaine
        showNewWeekSetup = true
    }
    
    private func resetCurrentWeek() {
        prioritiesManager.resetWeeklyData()
        HapticManager.shared.impact(.medium)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views
struct PriorityResultCard: View {
    let priority: Priority
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Numéro priorité
            ZStack {
                Circle()
                    .fill(priority.color.swiftUIColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("#\(index)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(priority.color.swiftUIColor)
            }
            
            // Détails
            VStack(alignment: .leading, spacing: 4) {
                Text(priority.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text("\(priority.tasks.filter { $0.isCompleted }.count)/\(priority.tasks.count) tâches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status
            VStack(spacing: 4) {
                if priority.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Terminé")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else {
                    Text("\(Int(priority.progress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Avancement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priority.isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let insight: WeeklyInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(insight.type.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: insight.type.icon)
                        .foregroundColor(insight.type.color)
                        .font(.headline)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NewWeekSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("🎯")
                    .font(.system(size: 60))
                
                VStack(spacing: 12) {
                    Text("Nouvelle Semaine")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Prêt à définir vos 3 nouvelles priorités ?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    // Reset et setup nouvelle semaine
                    PrioritiesManager.shared.resetWeeklyData()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Commencer la Nouvelle Semaine")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Nouvelle Semaine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Plus tard") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types
struct WeeklyInsight {
    let title: String
    let description: String
    let type: InsightType
}

enum InsightType {
    case success, good, improvement
    
    var color: Color {
        switch self {
        case .success: return .green
        case .good: return .blue
        case .improvement: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .good: return "star.circle.fill"
        case .improvement: return "arrow.up.circle.fill"
        }
    }
}

struct WeeklyWrapUpView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyWrapUpView()
    }
} 