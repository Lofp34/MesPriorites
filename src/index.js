// Priorités Semaine Pro - Version Web PWA
// Point d'entrée principal de l'application

import './styles.css';

// Configuration globale
const APP_CONFIG = {
  name: "Priorités Semaine Pro",
  version: "1.0.0",
  maxInteractionTime: 45, // secondes
  pomodoroConfig: {
    work: 25,
    shortBreak: 5,
    longBreak: 15
  }
};

// Données de priorités (chargées depuis l'analyse coach)
const INITIAL_PRIORITIES = [
  {
    id: 1,
    title: "Automatiser facturation",
    description: "Mettre en place un système automatisé pour la facturation",
    progress: 25,
    importance: 5,
    color: "#FF6B6B",
    deadline: "2025-02-01",
    category: "professional",
    tasks: [
      { id: 1, text: "Rechercher outils de facturation", completed: true },
      { id: 2, text: "Configurer Stripe/PayPal", completed: false },
      { id: 3, text: "Créer templates factures", completed: false }
    ]
  },
  {
    id: 2,
    title: "Booster prospection",
    description: "Améliorer le processus de prospection client",
    progress: 40,
    importance: 4,
    color: "#4ECDC4",
    deadline: "2025-01-25",
    category: "professional", 
    tasks: [
      { id: 4, text: "Optimiser profil LinkedIn", completed: true },
      { id: 5, text: "Créer séquences emails", completed: false },
      { id: 6, text: "Identifier 50 prospects", completed: false }
    ]
  },
  {
    id: 3,
    title: "Soigner sommeil",
    description: "Améliorer qualité et régularité du sommeil",
    progress: 60,
    importance: 5,
    color: "#45B7D1",
    deadline: "2025-01-31",
    category: "personal",
    tasks: [
      { id: 7, text: "Prendre mélatonine régulièrement", completed: true },
      { id: 8, text: "Coucher à 22h30 max", completed: false },
      { id: 9, text: "Pas d'écran 1h avant", completed: false }
    ]
  }
];

// Gestionnaire d'état global
class AppState {
  constructor() {
    this.priorities = this.loadPriorities();
    this.currentUser = this.loadUserData();
    this.focusSession = null;
    this.notifications = [];
    
    this.init();
  }

  init() {
    this.setupEventListeners();
    this.checkDailyRitual();
    this.registerServiceWorker();
    this.render();
  }

  loadPriorities() {
    const saved = localStorage.getItem('priorities');
    return saved ? JSON.parse(saved) : [...INITIAL_PRIORITIES];
  }

  loadUserData() {
    const saved = localStorage.getItem('userData');
    return saved ? JSON.parse(saved) : {
      level: 1,
      xp: 0,
      streak: 0,
      badges: [],
      totalSessions: 0
    };
  }

  savePriorities() {
    localStorage.setItem('priorities', JSON.stringify(this.priorities));
  }

  saveUserData() {
    localStorage.setItem('userData', JSON.stringify(this.currentUser));
  }

  setupEventListeners() {
    // Navigation
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-route]')) {
        e.preventDefault();
        this.navigate(e.target.dataset.route);
      }
    });

    // Mise à jour du progrès
    document.addEventListener('change', (e) => {
      if (e.target.matches('.progress-slider')) {
        this.updateProgress(parseInt(e.target.dataset.priorityId), parseInt(e.target.value));
      }
    });

    // Gestion des tâches
    document.addEventListener('click', (e) => {
      if (e.target.matches('.task-checkbox')) {
        this.toggleTask(parseInt(e.target.dataset.priorityId), parseInt(e.target.dataset.taskId));
      }
    });
  }

  navigate(route) {
    document.querySelectorAll('[data-page]').forEach(page => {
      page.style.display = 'none';
    });
    
    const targetPage = document.querySelector(`[data-page="${route}"]`);
    if (targetPage) {
      targetPage.style.display = 'block';
      this.updatePageContent(route);
    }
  }

  updateProgress(priorityId, newProgress) {
    const priority = this.priorities.find(p => p.id === priorityId);
    if (priority) {
      priority.progress = newProgress;
      this.savePriorities();
      this.addXP(5);
      this.render();
    }
  }

  toggleTask(priorityId, taskId) {
    const priority = this.priorities.find(p => p.id === priorityId);
    if (priority) {
      const task = priority.tasks.find(t => t.id === taskId);
      if (task) {
        task.completed = !task.completed;
        this.savePriorities();
        this.addXP(task.completed ? 10 : -10);
        this.updatePriorityProgress(priority);
        this.render();
      }
    }
  }

  updatePriorityProgress(priority) {
    const completedTasks = priority.tasks.filter(t => t.completed).length;
    const totalTasks = priority.tasks.length;
    const calculatedProgress = Math.round((completedTasks / totalTasks) * 100);
    
    if (calculatedProgress !== priority.progress) {
      priority.progress = calculatedProgress;
    }
  }

  addXP(points) {
    this.currentUser.xp += points;
    this.checkLevelUp();
    this.saveUserData();
  }

  checkLevelUp() {
    const newLevel = Math.floor(this.currentUser.xp / 100) + 1;
    if (newLevel > this.currentUser.level) {
      this.currentUser.level = newLevel;
      this.showLevelUp();
    }
  }

  showLevelUp() {
    this.showNotification(`🎉 Niveau ${this.currentUser.level} atteint !`);
  }

  showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.remove();
    }, 3000);
  }

  checkDailyRitual() {
    const lastCheck = localStorage.getItem('lastDailyCheck');
    const today = new Date().toDateString();
    
    if (lastCheck !== today) {
      // Déclencher check-in quotidien à 8h
      const now = new Date();
      if (now.getHours() >= 8) {
        this.showDailyCheckIn();
      }
    }
  }

  showDailyCheckIn() {
    this.navigate('daily-checkin');
  }

  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        await navigator.serviceWorker.register('/service-worker.js');
        console.log('Service Worker enregistré');
      } catch (error) {
        console.log('Erreur Service Worker:', error);
      }
    }
  }

  render() {
    this.renderPriorities();
    this.renderUserStats();
    this.renderFocusMode();
  }

  renderPriorities() {
    const container = document.getElementById('priorities-container');
    if (!container) return;

    container.innerHTML = this.priorities.map(priority => `
      <div class="priority-card" style="border-left: 4px solid ${priority.color}">
        <div class="priority-header">
          <h3>${priority.title}</h3>
          <span class="importance">${'⭐'.repeat(priority.importance)}</span>
        </div>
        <div class="progress-container">
          <div class="progress-bar">
            <div class="progress-fill" style="width: ${priority.progress}%; background: ${priority.color}"></div>
          </div>
          <span class="progress-text">${priority.progress}%</span>
        </div>
        <div class="progress-controls">
          <input type="range" class="progress-slider" 
                 data-priority-id="${priority.id}"
                 min="0" max="100" value="${priority.progress}">
        </div>
        <div class="tasks-container">
          ${priority.tasks.map(task => `
            <label class="task-item">
              <input type="checkbox" class="task-checkbox" 
                     data-priority-id="${priority.id}" 
                     data-task-id="${task.id}"
                     ${task.completed ? 'checked' : ''}>
              <span class="task-text ${task.completed ? 'completed' : ''}">${task.text}</span>
            </label>
          `).join('')}
        </div>
      </div>
    `).join('');
  }

  renderUserStats() {
    const statsContainer = document.getElementById('user-stats');
    if (!statsContainer) return;

    const levelNames = ['Débutant', 'Amateur', 'Confirmé', 'Expert', 'Maître', 'Légende'];
    const currentLevelName = levelNames[Math.min(this.currentUser.level - 1, levelNames.length - 1)];

    statsContainer.innerHTML = `
      <div class="stats-card">
        <h4>Votre Progression</h4>
        <div class="level-info">
          <span class="level">Niveau ${this.currentUser.level}</span>
          <span class="level-name">${currentLevelName}</span>
        </div>
        <div class="xp-bar">
          <div class="xp-fill" style="width: ${(this.currentUser.xp % 100)}%"></div>
        </div>
        <div class="stats-grid">
          <div class="stat">
            <span class="stat-value">${this.currentUser.xp}</span>
            <span class="stat-label">XP Total</span>
          </div>
          <div class="stat">
            <span class="stat-value">${this.currentUser.streak}</span>
            <span class="stat-label">Jours Consécutifs</span>
          </div>
        </div>
      </div>
    `;
  }

  renderFocusMode() {
    const focusContainer = document.getElementById('focus-mode');
    if (!focusContainer) return;

    focusContainer.innerHTML = `
      <div class="focus-card">
        <h4>🎯 Mode Focus</h4>
        <div class="pomodoro-timer">
          <div class="timer-display" id="timer-display">25:00</div>
          <div class="timer-controls">
            <button id="start-focus" class="btn-primary">Démarrer Focus</button>
            <button id="pause-focus" class="btn-secondary" style="display: none;">Pause</button>
          </div>
        </div>
        <div class="focus-stats">
          <span>Sessions aujourd'hui: ${this.currentUser.totalSessions}</span>
        </div>
      </div>
    `;

    this.setupFocusMode();
  }

  setupFocusMode() {
    const startBtn = document.getElementById('start-focus');
    const pauseBtn = document.getElementById('pause-focus');
    
    if (startBtn) {
      startBtn.addEventListener('click', () => this.startFocusSession());
    }
    
    if (pauseBtn) {
      pauseBtn.addEventListener('click', () => this.pauseFocusSession());
    }
  }

  startFocusSession() {
    if (this.focusSession) return;

    this.focusSession = {
      startTime: Date.now(),
      duration: APP_CONFIG.pomodoroConfig.work * 60 * 1000,
      paused: false
    };

    this.runFocusTimer();
    document.getElementById('start-focus').style.display = 'none';
    document.getElementById('pause-focus').style.display = 'inline-block';
  }

  pauseFocusSession() {
    if (this.focusSession) {
      this.focusSession.paused = !this.focusSession.paused;
      document.getElementById('pause-focus').textContent = 
        this.focusSession.paused ? 'Reprendre' : 'Pause';
    }
  }

  runFocusTimer() {
    const updateTimer = () => {
      if (!this.focusSession || this.focusSession.paused) {
        setTimeout(updateTimer, 1000);
        return;
      }

      const elapsed = Date.now() - this.focusSession.startTime;
      const remaining = Math.max(0, this.focusSession.duration - elapsed);
      
      if (remaining === 0) {
        this.completeFocusSession();
        return;
      }

      const minutes = Math.floor(remaining / 60000);
      const seconds = Math.floor((remaining % 60000) / 1000);
      document.getElementById('timer-display').textContent = 
        `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

      setTimeout(updateTimer, 1000);
    };

    updateTimer();
  }

  completeFocusSession() {
    this.focusSession = null;
    this.currentUser.totalSessions++;
    this.addXP(50);
    this.showNotification('🎉 Session Focus terminée ! +50 XP');
    
    document.getElementById('start-focus').style.display = 'inline-block';
    document.getElementById('pause-focus').style.display = 'none';
    document.getElementById('timer-display').textContent = '25:00';
    
    this.render();
  }

  updatePageContent(route) {
    switch(route) {
      case 'home':
        this.render();
        break;
      case 'insights':
        this.renderInsights();
        break;
      case 'daily-checkin':
        this.renderDailyCheckIn();
        break;
    }
  }

  renderInsights() {
    const insightsContainer = document.getElementById('insights-content');
    if (!insightsContainer) return;

    const avgProgress = Math.round(
      this.priorities.reduce((sum, p) => sum + p.progress, 0) / this.priorities.length
    );

    insightsContainer.innerHTML = `
      <div class="insights-grid">
        <div class="insight-card">
          <h4>Progression Moyenne</h4>
          <div class="big-number">${avgProgress}%</div>
        </div>
        <div class="insight-card">
          <h4>Priorité la Plus Avancée</h4>
          <div class="priority-highlight">
            ${this.priorities.reduce((max, p) => p.progress > max.progress ? p : max).title}
          </div>
        </div>
        <div class="insight-card">
          <h4>Focus Sessions</h4>
          <div class="big-number">${this.currentUser.totalSessions}</div>
        </div>
      </div>
    `;
  }

  renderDailyCheckIn() {
    const checkInContainer = document.getElementById('checkin-content');
    if (!checkInContainer) return;

    checkInContainer.innerHTML = `
      <div class="checkin-form">
        <h3>🌅 Check-in Quotidien</h3>
        <div class="question">
          <label>Comment vous sentez-vous aujourd'hui ?</label>
          <select id="mood-select">
            <option value="great">🔥 En forme !</option>
            <option value="good">😊 Bien</option>
            <option value="okay">😐 Correct</option>
            <option value="tired">😴 Fatigué</option>
          </select>
        </div>
        <div class="question">
          <label>Quel est votre objectif principal aujourd'hui ?</label>
          <textarea id="daily-goal" placeholder="Ex: Avancer sur la prospection..."></textarea>
        </div>
        <div class="question">
          <label>Y a-t-il des obstacles à prévoir ?</label>
          <textarea id="obstacles" placeholder="Ex: Réunion importante cet après-midi..."></textarea>
        </div>
        <button id="submit-checkin" class="btn-primary">Valider le Check-in</button>
      </div>
    `;

    document.getElementById('submit-checkin').addEventListener('click', () => {
      this.submitDailyCheckIn();
    });
  }

  submitDailyCheckIn() {
    const mood = document.getElementById('mood-select').value;
    const goal = document.getElementById('daily-goal').value;
    const obstacles = document.getElementById('obstacles').value;

    // Sauvegarder le check-in
    const checkIn = {
      date: new Date().toDateString(),
      mood,
      goal,
      obstacles
    };

    const checkIns = JSON.parse(localStorage.getItem('dailyCheckIns') || '[]');
    checkIns.push(checkIn);
    localStorage.setItem('dailyCheckIns', JSON.stringify(checkIns));
    localStorage.setItem('lastDailyCheck', new Date().toDateString());

    this.addXP(25);
    this.showNotification('✅ Check-in complété ! +25 XP');
    this.navigate('home');
  }
}

// Initialisation de l'application
document.addEventListener('DOMContentLoaded', () => {
  // Création de la structure HTML de base
  const appHTML = `
    <div id="app">
      <nav class="navbar">
        <div class="nav-brand">🎯 Priorités Semaine Pro</div>
        <div class="nav-links">
          <a href="#" data-route="home">Accueil</a>
          <a href="#" data-route="insights">Insights</a>
          <a href="#" data-route="daily-checkin">Check-in</a>
        </div>
      </nav>

      <main class="main-content">
        <div data-page="home" class="page">
          <div class="page-header">
            <h1>Mes 3 Priorités Semaine</h1>
            <p>Interaction cible : &lt;45 secondes ⚡</p>
          </div>
          
          <div id="user-stats"></div>
          <div id="priorities-container"></div>
          <div id="focus-mode"></div>
        </div>

        <div data-page="insights" class="page" style="display: none;">
          <div class="page-header">
            <h1>📊 Insights & Analytics</h1>
          </div>
          <div id="insights-content"></div>
        </div>

        <div data-page="daily-checkin" class="page" style="display: none;">
          <div class="page-header">
            <h1>🌅 Check-in Quotidien</h1>
          </div>
          <div id="checkin-content"></div>
        </div>
      </main>
    </div>
  `;

  document.body.innerHTML = appHTML;
  
  // Initialiser l'application
  const app = new AppState();
  
  // Export global pour debug
  window.app = app;
});

// Export pour les modules
export default APP_CONFIG; 