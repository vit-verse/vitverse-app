# VIT Verse (VIT Connect)

<div align="center">

**An unofficial, student-developed companion app for VIT Chennai students**

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)

[Features](#features) • [Installation](#installation) • [Setup](#setup) • [Contributing](#contributing) • [License](#license)

</div>

---

## 📋 About

VIT Verse is a feature-rich Flutter application designed to enhance the academic experience of VIT Chennai students. It provides seamless access to VTOP data, community features, and campus utilities... all in one place.

**⚠️ Disclaimer:** This app is NOT officially affiliated with, endorsed by, or connected to VIT Chennai or VIT University.

---

## ✨ Features

### 📚 VTOP Integration
- **Smart Login** with 3-stage CAPTCHA solving (95%+ accuracy)
- **Profile & Academic Data** - View attendance, marks, timetable, and grades
- **Real-time Sync** - Fetch latest data directly from VTOP
- **Offline Access** - All data cached locally with AES-256 encryption

### 📊 Performance Analytics
- **CGPA/GPA Calculator** with predictor and estimator
- **Grade History** with visual charts and insights
- **Attendance Tracking** with alerts and predictions
- **Student Report Generation** - Generate comprehensive PDF reports

### 🎓 Community Features
- **Faculty Ratings** - Faculty reviews and ratings/comments
- **Cab Share** - Find students for ride-sharing
- **Lost & Found** - Report and find lost items on campus
- **Events** - Post and discover campus events

### 🛠️ Utilities
- **Mess Menu** - Daily meal schedules
- **Laundry Tracking** - Track laundry status
- **Exam Schedule** - Never miss an exam
- **Push Notifications** - Lost Found, Cab Share, Event updates/alerts

### 🎨 User Experience
- **Dark/Light Mode** with customizable themes
- **Widget Customization** - Personalize your dashboard
- **Smooth Animations** with Lottie
- **Responsive Design** for all screen sizes

---

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Git

### Download
Clone the repository:
```bash
git clone https://github.com/vit-verse/vitverse-app.git
cd vit-connect
```

---

## ⚙️ Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Environment Variables
Create a `.env` file in the root directory:
```bash
cp .env.example .env
```

Edit `.env` and add your configuration:
```env
# Supabase - Main database for community features
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Supabase Events - Separate database for events feature
SUPABASE_EVENTS_URL=https://your-events-project.supabase.co
SUPABASE_EVENTS_ANON_KEY=your_events_supabase_anon_key_here

# GitHub Token - For version checking and updates
GITHUB_VITCONNECT_TOKEN=your_github_token_here

# Security Headers
PYQ_SECRET_HEADER=your_pyq_secret_header
EVENTS_SECRET_HEADER=your_events_secret_header
```

### 3. Firebase Setup (Optional)
- The app includes Firebase configuration for analytics, crashlytics, and messaging
- `google-services.json` is already configured for the project
- Firebase API keys are SHA-1 restricted for security

### 4. Run the App
```bash
flutter run --dart-define-from-file=.env
```

Or use the VS Code task: **"Load .env for debugging"**

---

## 🏗️ Project Structure

```
lib/
├── core/              # Core utilities, config, theme, services
├── features/          # Feature modules (authentication, dashboard, etc.)
├── firebase/          # Firebase integration (analytics, crashlytics)
├── supabase/          # Supabase integration (optional cloud features)
└── main.dart          # App entry point

assets/
├── icons/             # App icons and UI assets
├── images/            # Images and illustrations
├── lottie/            # Lottie animation files
└── ml/                # ML models for CAPTCHA solving
```

---

## 🔒 Security & Privacy

- **VTOP Credentials**: AES-256 encrypted and stored locally only
- **No Data Collection**: Your academic data never leaves your device
- **Local CAPTCHA Solving**: On-device ML models (no external API calls)
- **Firebase Analytics**: Anonymous usage statistics only
- **Community Features**: Voluntary participation with visible identity

For complete details, see [Privacy Policy](PRIVACY_POLICY.md) .

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start
1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'feat: add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact & Support

**Developer:** Divyanshu Patel  
**Email:** itzdivyanshupatel@gmail.com  
**GitHub:** [@divyanshupatel17](https://github.com/divyanshupatel17)  
**LinkedIn:** [Divyanshu Patel](https://www.linkedin.com/in/patel-divyanshu/)


---

## ⚠️ Important Notes

1. **Educational Purpose**: This app is built for educational purposes and to enhance student experience
2. **No Warranty**: The app is provided "as is" without any warranties
3. **Not Affiliated**: This is an unofficial app and not endorsed by VIT
4. **Use Responsibly**: Use only your own VTOP credentials and respect VIT's policies

---

## 🙏 Acknowledgments

- VIT Chennai students for feedback and testing
- Flutter & Dart communities for excellent documentation
- All open-source contributors whose packages made this possible

---

<div align="center">

**Made with ❤️ by Div**

⭐ Star this repo if you find it helpful!

</div>