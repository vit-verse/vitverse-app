# Privacy Policy

**Last Updated:** December 17, 2025

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
When you voluntarily participate in community features (Cab Share, Lost & Found), your name and registration number from your VTOP profile may be displayed to other app users. This data is stored in Supabase cloud database for sharing purposes.

Faculty ratings are completely anonymous—no personally identifiable information is collected or displayed. Ratings are stored via Google Apps Script API (Google Sheets).

### 1.4 Analytics & Diagnostics
We use Firebase Analytics and Firebase Crashlytics to collect anonymous usage statistics, crash reports, and app performance data. This helps us improve stability and user experience. No personally identifiable information is included in analytics data.

### 1.5 Device Permissions
- **Camera**: For QR/barcode scanning features (optional)
- **Storage**: For saving images and timetables (optional)
- **Internet**: Required for VTOP communication and app functionality

---

## 2. Data Usage

- Your VTOP credentials authenticate you with VIT's official VTOP portal only
- Academic data is displayed within the app for your personal use
- Community feature participation is voluntary and displays your identity only when you create posts
- Anonymous analytics improve app performance and stability
- **We do not sell, rent, or share your personal data with third parties**

---

## 3. Security

All sensitive data is encrypted and stored locally on your device. CAPTCHA solving uses on-device machine learning models (custom neural network and Google ML Kit OCR). No CAPTCHA images or credentials are transmitted to external servers during authentication.

---

## 4. Third-Party Services

This app integrates with:
- **VTOP (VIT Official Portal)**: For fetching academic data
- **Firebase (Google)**: For analytics, crash reporting, and app stability
- **Supabase**: For cloud database storage (Cab Share, Lost & Found features)
- **Google Apps Script API**: For faculty rating storage (Google Sheets backend)

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
- Contact us with privacy concerns at **itzdivyanshupatel@gmail.com**

---

## 7. Changes to This Policy

We may update this privacy policy from time to time. Continued use of the app after changes indicates your acceptance of the updated policy.

---

**Contact:**  
Email: itzdivyanshupatel@gmail.com  

### 5.1 VTOP (VIT Official Portal)
- **Purpose**: The App communicates directly with VTOP to authenticate and fetch your academic data.
- **Data Sent**: Your username and password (encrypted in transit via HTTPS).
- **Privacy**: VTOP's own privacy policy applies to data stored on their servers.

### 5.2 Supabase (Cloud Database)
- **Purpose**: Store and retrieve community posts (Cab Share, Lost & Found).
- **Data Sent**: Name, registration number, post content, timestamps.
- **Privacy**: Supabase's privacy policy applies to data stored in their cloud database.

### 5.3 Google Apps Script API (Google Sheets)
- **Purpose**: Store anonymous faculty ratings.
- **Data Sent**: Faculty name, rating scores, anonymous comments (no personal identifiers).
- **Privacy**: Google's privacy policy applies to data stored in Google Sheets.

### 5.4 Firebase (Analytics & Crashlytics)
- **Purpose**: Collect anonymous usage statistics and crash reports.
- **Privacy**: Firebase's privacy policy applies. No personally identifiable information is sent.

---

## 6. Your Rights

- **Access**: You can view all your data within the App.
- **Deletion**: You can delete your local data by logging out or uninstalling the App.
- **Community Posts**: You can delete your own posts from Cab Share and Lost & Found within the App.
- **Opt-Out**: You cannot opt out of Firebase Analytics/Crashlytics without uninstalling the App.

---

## 7. Data Retention

- **Local Data**: Academic data is stored on your device until you log out or uninstall the App.
- **Community Posts**: Cab Share and Lost & Found posts are stored in Supabase cloud database until you delete them.
- **Faculty Ratings**: Stored anonymously in Google Sheets indefinitely.
- **Analytics Data**: Retained by Firebase according to their retention policy.

---

## 8. No Control or Responsibility

VIT Verse is a third-party app developed independently by students. We do **NOT** have any control over:

- VTOP's availability, uptime, or data accuracy.
- VIT Chennai's official policies or academic data.
- Supabase, Google Apps Script API, or Firebase service availability.

We are **NOT** responsible for:

- Any data loss, inaccuracies, or issues arising from VTOP servers.
- Any consequences of using community features (Cab Share, Lost & Found, Faculty Rating).
- Any academic or administrative decisions made by VIT Chennai.

**Use the App at your own risk.**


---

## 9. Changes to This Policy

We may update this privacy policy from time to time. Check the "Last Updated" date at the top. Continued use of the App after changes constitutes acceptance.

---

## 10. Contact Us

For questions or concerns about this privacy policy:

- **Email**: itzdivyanshupatel@gmail.com
---

**By using VIT Verse, you agree to this Privacy Policy.**

