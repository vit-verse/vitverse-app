# Privacy Policy

**Last Updated:** January 14, 2026

VIT Verse (also referred to as "VIT Connect" in code and internal references) is an unofficial, student-developed companion app for VIT Chennai students. This privacy policy explains what data we collect, how we use it, and your rights regarding your information.

---

## 1. Data Collection

### 1.1 VTOP Login Credentials
Your VTOP username and password are encrypted using AES-256 encryption and stored locally on your device via Flutter Secure Storage. These credentials are used exclusively to authenticate with VIT's official VTOP portal to retrieve your academic information. **Your credentials never leave your device** and are not transmitted to any third-party servers or services operated by us.

### 1.2 Academic Information
Upon successful authentication, the app fetches your academic data directly from VTOP, including:
- Profile details (name, registration number, email)
- Course enrollment and timetable
- Attendance records and summaries
- Marks, assessments, and grade history
- Exam schedules and fee receipts
- Faculty information and announcements

All academic data is stored locally on your device using SQLite and encrypted storage. **This information is never shared with third parties.**

### 1.3 Community Features
When you voluntarily participate in community features (Cab Share, Lost & Found, Events), your name and registration number from your VTOP profile may be displayed to other app users. This data is stored in Supabase cloud database for sharing purposes.

**Faculty Ratings**: When you submit a rating, no personal details are shown to other users with your rating. However, when you add comments, your name is displayed as "Commented by" to prevent spam and maintain accountability. Faculty ratings data is stored in Supabase cloud database.

**Events**: When posting events, your name and registration number are displayed. Events data is stored in Supabase cloud database.

### 1.4 Push Notifications
We use Firebase Cloud Messaging (FCM) with topic-based subscriptions to send push notifications for:
- Cab Share updates and requests
- Lost & Found alerts
- Event announcements

Notifications are enabled by default. You can unsubscribe from any notification topic in the Notification Settings page. **No FCM tokens are stored on our servers** — we use topic-based messaging only.

### 1.5 Analytics & Diagnostics
We use Firebase Analytics and Firebase Crashlytics to collect anonymous usage statistics, crash reports, and app performance data. This helps us improve stability and user experience. No personally identifiable information is included in analytics data.

### 1.6 Device Permissions
- **Camera**: For QR/barcode scanning features (optional)
- **Storage**: For saving images, reports, and timetables (optional)
- **Notifications**: For community feature alerts (optional, can be disabled per topic)
- **Internet**: Required for VTOP communication and app functionality

---

## 2. Data Usage

- Your VTOP credentials authenticate you with VIT's official VTOP portal only
- Academic data is displayed within the app for your personal use
- Community feature participation is voluntary and displays your identity only when you create posts
- Push notifications keep you informed about community features (topic-based, opt-out available)
- Anonymous analytics improve app performance and stability
- **We do not sell, rent, or share your personal data with third parties**

---

## 3. Security

All sensitive data is encrypted and stored locally on your device. CAPTCHA solving uses on-device machine learning models (custom neural network). No CAPTCHA images or credentials are transmitted to external servers during authentication.

---

## 4. Third-Party Services

This app integrates with:
- **VTOP (VIT Official Portal)**: For fetching academic data
- **Firebase (Google)**: For analytics, crash reporting, push notifications (topic-based), and app stability
- **Supabase**: For cloud database storage (Cab Share, Lost & Found, Faculty Ratings, Events)
- **Google Cloud Storage**: For PYQ (Previous Year Questions) file storage

Each third-party service has its own privacy policy. We are not responsible for their data handling practices.

---

## 5. Disclaimer

**VIT Verse is an unofficial, student-developed app and is not affiliated with, endorsed by, or connected to VIT Chennai or VIT University.** We are not responsible for:
- Data scraping, misuse, or unauthorized access by third parties
- VTOP service disruptions, downtime, or data inaccuracies
- Any issues arising from third-party service integrations
- Loss of data due to device failure, app uninstallation, or other technical issues

Use this app at your own risk. **We provide no warranties or guarantees regarding data accuracy, app availability, or functionality.**

---

## 6. Your Rights

You can:
- Delete your locally stored data by uninstalling the app or clearing app data
- Stop using community features at any time
- Manage notification preferences in app settings
- Delete your own posts from community features within the app
- Contact us with privacy concerns at **itzdivyanshupatel@gmail.com**

---

## 7. Third-Party Service Details

### 7.1 VTOP (VIT Official Portal)
- **Purpose**: The App communicates directly with VTOP to authenticate and fetch your academic data.
- **Data Sent**: Your username and password (encrypted in transit via HTTPS).
- **Privacy**: VTOP's own privacy policy applies to data stored on their servers.

### 7.2 Supabase (Cloud Database)
- **Purpose**: Store and retrieve community data (Cab Share, Lost & Found, Faculty Ratings, Events).
- **Data Sent**: Name, registration number, post content, ratings, timestamps.
- **Privacy**: Supabase's privacy policy applies to data stored in their cloud database.

### 7.3 Firebase (Analytics, Crashlytics, Cloud Messaging)
- **Purpose**: Collect anonymous usage statistics, crash reports, and deliver topic-based push notifications.
- **Data Sent**: Anonymous analytics, crash logs. No FCM tokens stored — topic subscriptions only.
- **Privacy**: Firebase's privacy policy applies. No personally identifiable information is sent in analytics.

### 7.4 Google Cloud Storage
- **Purpose**: Store and serve PYQ (Previous Year Questions) files.
- **Privacy**: Google Cloud's privacy policy applies.

---

## 8. Data Retention

- **Local Data**: Academic data is stored on your device until you log out or uninstall the App.
- **Community Posts**: Cab Share, Lost & Found, and Events posts are stored in Supabase cloud database until you delete them.
- **Faculty Ratings**: Stored in Supabase indefinitely.
- **Analytics Data**: Retained by Firebase according to their retention policy.
- **Push Notifications**: Topic subscriptions managed locally on device.

---

## 9. No Control or Responsibility

VIT Verse is a third-party app developed independently by students. We do **NOT** have any control over:

- VTOP's availability, uptime, or data accuracy.
- VIT Chennai's official policies or academic data.
- Supabase, Firebase, Google Cloud, or other third-party service availability.

We are **NOT** responsible for:

- Any data loss, inaccuracies, or issues arising from VTOP servers.
- Any consequences of using community features (Cab Share, Lost & Found, Faculty Rating, Events).
- Any academic or administrative decisions made by VIT Chennai.

**Use the App at your own risk.**

---

## 10. Changes to This Policy

We may update this privacy policy from time to time. Check the "Last Updated" date at the top. Continued use of the App after changes constitutes acceptance.

---

## 11. Contact Us

For questions or concerns about this privacy policy:

- **Email**: itzdivyanshupatel@gmail.com

---

**By using VIT Verse, you agree to this Privacy Policy.**

