# Jamendo Music Discovery Application

A full-stack cross-platform music streaming and discovery application built with **Flutter** and **Python Flask**, powered by the **Jamendo API** and **Firebase Authentication**.

---

## 🛠️ Tech Stack

### **Frontend**
* **Framework:** Flutter (Cross-platform support for Android, iOS, Web, macOS, Windows, Linux)
* **Authentication & Services:** Firebase Auth (`auth_services.dart`)
* **Core Components:** Custom audio manager, dynamic home screen, search, recommendations, favorites, profile management, and persistent playback controls (`now_playing_bar.dart`).

### **Backend**
* **Framework:** Python Flask (`app.py`)
* **Libraries:** `flask-cors`, `requests`, `python-dotenv`
* **API Integration:** Jamendo REST API (`v3.0/tracks`) for real-time music search, charts, and recommendations.

---

## 📂 Project Structure

```text
├── backend/
│   └── app.py                  # Flask backend server & Jamendo API integration
└── frontend/
    ├── lib/
    │   ├── authentication/     # Firebase auth services & configuration
    │   │   ├── auth_services.dart
    │   │   └── firebase_options.dart
    │   └── screens/            # UI screens & audio components
    │       ├── audio_manager.dart
    │       ├── favoritescreen.dart
    │       ├── historyscreen.dart
    │       ├── homescreen.dart
    │       ├── loginscreen.dart
    │       ├── now_playing_bar.dart
    │       ├── profilescreen.dart
    │       ├── recommendationscreen.dart
    │       ├── selectionscreen.dart
    │       ├── signupscreen.dart
    │       └── usernamescreen.dart
    ├── pubspec.yaml            # Flutter dependencies
    └── ...
