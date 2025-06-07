import SwiftUI

struct ContentView: View {
    @StateObject private var prioritiesManager = PrioritiesManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Onglet Priorités
            HomeView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Priorités")
                }
                .tag(0)
            
            // Onglet Focus
            FocusModeView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Focus")
                }
                .tag(1)
            
            // Onglet Insights
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Insights")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onAppear {
            // Initialiser les données par défaut si première ouverture
            if prioritiesManager.priorities.isEmpty {
                prioritiesManager.loadInitialData()
            }
            
            // Configurer les notifications
            NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleDailyCheckIn()
            NotificationManager.shared.scheduleWeeklyWrapUp()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 