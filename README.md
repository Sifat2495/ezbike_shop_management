# 📱 ezbike shop management app

A simple Flutter application integrated with Firebase, targeting Android devices only.

## 🚀 Features

- Firebase Authentication (Email/Google)
- Phone number authentication with external sms OTP (Not Firebase OTP). 
- Firestore Database integration
- Android-only setup
- Clean architecture
- Null safety enabled

## 🛠️ Getting Started

### 🔧 Prerequisites

- Flutter SDK
- Android Studio or VS Code
- Firebase project configured

### 📦 Installation

1. **Clone the repo**:
     git clone https://github.com/your-username/flutter-firebase-android.git
     cd flutter-firebase-android
   
   **Install dependencies**:
     flutter pub get
   
   **Set up Firebase**:
     - Go to Firebase Console
     - Create or use an existing project
     - Register your Android app using your app's package name
     - Download the google-services.json file
     - Place it in: android/app/google-services.json
       
    **Run the app**:
     - flutter run
       
🔐 **Firebase Configuration Notice**
This repository excludes sensitive Firebase configuration files (google-services.json) for security reasons. You must provide your own to run the app.


🧾 **License**
This project is open source and available under the MIT License.

🤝 **Contributions**
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.
