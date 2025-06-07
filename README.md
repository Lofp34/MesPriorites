# Priorités Semaine Pro - iOS App

## 📱 Description
Application iOS native pour gérer 3 priorités hebdomadaires avec suivi de tâches, focus mode et gamification douce.

## 🚀 Installation & Lancement Local

### Prérequis
- macOS 12+ avec Xcode 14+
- iPhone 12+ ou simulateur iOS 15+
- Compte développeur Apple (gratuit suffisant pour tests)

### Étapes
1. **Cloner & ouvrir**
   ```bash
   cd /Users/laurents/Documents/Mes_Priorités
   open PrioritésSemainePro.xcodeproj
   ```

2. **Configurer le signing**
   - Dans Xcode → Project Settings → Signing & Capabilities
   - Sélectionner votre Team ID
   - Changer Bundle ID : `com.votrecompte.priorites-semaine-pro`

3. **Lancer sur simulateur**
   - Cmd+R ou bouton Play
   - Choisir iPhone 12+ dans la liste des simulateurs

4. **Installer sur iPhone physique**
   - Connecter l'iPhone via USB
   - Faire confiance à l'ordinateur
   - Sélectionner votre iPhone comme destination
   - Cmd+R pour installer

## 🌐 Déploiement Web (PWA via Vercel)

L'app sera également packagée comme PWA pour Vercel :

```bash
# Build web version
npm run build:web
vercel --prod
```

URL finale : `https://priorites-semaine-pro.vercel.app`

## ⚡ Fonctionnalités
- ✅ 3 priorités hebdomadaires avec progression visuelle
- ✅ Éditeur de priorités (importance, couleur, deadline)
- ✅ Gestion tâches : drag & drop, swipe, quick-add vocal
- ✅ Focus Mode avec minuteur Pomodoro
- ✅ Daily Check-in (8h) & Weekly Wrap-up (vendredi 17h)
- ✅ Gamification : niveaux Rookie→Wizard, badges secrets
- ✅ Mode sombre + accessibilité VoiceOver
- ✅ Données pré-remplies basées sur vos priorités réelles

## 📊 KPI Cibles
- Activation 24h : 70%
- Sessions/jour : 2+ (60% utilisateurs)
- Rétention W3 : 40%
- Complétion priorités : ≥75%

## 🛠 Architecture
- SwiftUI + Core Data + UserNotifications
- MVVM avec services dédiés
- Navigation optimisée une main
- Feedback haptique natif 