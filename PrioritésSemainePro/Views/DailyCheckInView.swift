import SwiftUI

struct DailyCheckInView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var gamificationManager = GamificationManager.shared
    
    @State private var progressResponse = ""
    @State private var blockerResponse = ""
    @State private var nextStepResponse = ""
    @State private var currentQuestionIndex = 0
    @State private var responses: [String] = ["", "", ""]
    @State private var showConfetti = false
    
    private let questions = [
        Question(
            title: "Progression d'hier",
            prompt: "Qu'avez-vous accompli sur vos priorités hier ?",
            placeholder: "Ex: Terminé 3 tâches de facturation, avancé sur le site...",
            icon: "checkmark.circle.fill",
            color: .green
        ),
        Question(
            title: "Blocages actuels",
            prompt: "Y a-t-il des obstacles qui vous ralentissent ?",
            placeholder: "Ex: Attente retour client, besoin formation sur l'outil...",
            icon: "exclamationmark.triangle.fill",
            color: .orange
        ),
        Question(
            title: "Prochaine étape",
            prompt: "Quelle est votre priorité #1 aujourd'hui ?",
            placeholder: "Ex: Finaliser le workflow Zapier, appeler 3 prospects...",
            icon: "arrow.right.circle.fill",
            color: .blue
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Current question
                ScrollView {
                    VStack(spacing: 24) {
                        currentQuestionView
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .overlay(
                // Confetti animation
                ConfettiView()
                    .opacity(showConfetti ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showConfetti)
            )
        }
    }
    
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(0..<questions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentQuestionIndex ? questions[index].color : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut(duration: 0.3), value: currentQuestionIndex)
                    
                    if index < questions.count - 1 {
                        Rectangle()
                            .fill(index < currentQuestionIndex ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentQuestionIndex)
                    }
                }
            }
            
            Text("\(currentQuestionIndex + 1)/\(questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var currentQuestionView: some View {
        let question = questions[currentQuestionIndex]
        
        return VStack(spacing: 24) {
            // Question icon and title
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(question.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: question.icon)
                        .font(.largeTitle)
                        .foregroundColor(question.color)
                }
                
                VStack(spacing: 8) {
                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(question.prompt)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Response text area
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $responses[currentQuestionIndex])
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(question.color.opacity(0.3), lineWidth: responses[currentQuestionIndex].isEmpty ? 0 : 2)
                    )
                
                if responses[currentQuestionIndex].isEmpty {
                    Text(question.placeholder)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(responses[currentQuestionIndex].count)/500")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick suggestions (for faster input)
            if currentQuestionIndex == 2 { // Next step question
                quickSuggestionsView
            }
        }
    }
    
    private var quickSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions rapides :")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(quickSuggestions, id: \.self) { suggestion in
                    Button {
                        responses[currentQuestionIndex] = suggestion
                        HapticManager.shared.selection()
                    } label: {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemBlue).opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous button
            if currentQuestionIndex > 0 {
                Button("Précédent") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentQuestionIndex -= 1
                    }
                    HapticManager.shared.selection()
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }
            
            // Next/Finish button
            Button(currentQuestionIndex == questions.count - 1 ? "Terminer" : "Suivant") {
                if currentQuestionIndex == questions.count - 1 {
                    completeCheckIn()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentQuestionIndex += 1
                    }
                    HapticManager.shared.selection()
                }
            }
            .disabled(responses[currentQuestionIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .foregroundColor(responses[currentQuestionIndex].isEmpty ? .secondary : .blue)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(responses[currentQuestionIndex].isEmpty ? Color.clear : Color.blue.opacity(0.1))
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    private func completeCheckIn() {
        // Sauvegarder les réponses
        let checkInData = DailyCheckInData(
            date: Date(),
            progressResponse: responses[0],
            blockerResponse: responses[1],
            nextStepResponse: responses[2]
        )
        
        saveDailyCheckIn(checkInData)
        
        // Gamification
        gamificationManager.addExperience(10)
        gamificationManager.checkBadgeProgress()
        
        // Mark as completed for today
        UserDefaults.standard.set(true, forKey: "CheckInCompleted-\(Calendar.current.dateComponents([.year, .month, .day], from: Date()))")
        
        // Feedback
        HapticManager.shared.notification(.success)
        
        // Show confetti animation
        showConfetti = true
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func saveDailyCheckIn(_ data: DailyCheckInData) {
        var savedCheckIns = loadDailyCheckIns()
        savedCheckIns.append(data)
        
        // Garder seulement les 30 derniers check-ins
        if savedCheckIns.count > 30 {
            savedCheckIns = Array(savedCheckIns.suffix(30))
        }
        
        do {
            let encoded = try JSONEncoder().encode(savedCheckIns)
            UserDefaults.standard.set(encoded, forKey: "DailyCheckIns")
        } catch {
            print("Erreur sauvegarde check-in: \(error)")
        }
    }
    
    private func loadDailyCheckIns() -> [DailyCheckInData] {
        guard let data = UserDefaults.standard.data(forKey: "DailyCheckIns") else { return [] }
        
        do {
            return try JSONDecoder().decode([DailyCheckInData].self, from: data)
        } catch {
            print("Erreur chargement check-ins: \(error)")
            return []
        }
    }
    
    private let quickSuggestions = [
        "Finaliser facturation",
        "Appeler 3 prospects",
        "Mettre à jour site",
        "Session Focus 2h",
        "Revoir priorités",
        "Déléguer tâches admin"
    ]
}

// MARK: - Supporting Types
struct Question {
    let title: String
    let prompt: String
    let placeholder: String
    let icon: String
    let color: Color
}

struct DailyCheckInData: Codable {
    let date: Date
    let progressResponse: String
    let blockerResponse: String
    let nextStepResponse: String
}

struct ConfettiView: View {
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                ConfettiPiece()
            }
        }
    }
}

struct ConfettiPiece: View {
    @State private var animate = false
    private let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow]
    private let startX = Double.random(in: 0...UIScreen.main.bounds.width)
    private let delay = Double.random(in: 0...2)
    
    var body: some View {
        Circle()
            .fill(colors.randomElement() ?? .blue)
            .frame(width: 8, height: 8)
            .position(x: startX, y: animate ? UIScreen.main.bounds.height + 50 : -50)
            .animation(
                Animation.linear(duration: 3)
                    .delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

struct DailyCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        DailyCheckInView()
    }
} 