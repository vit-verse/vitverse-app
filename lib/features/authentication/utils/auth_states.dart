// Authentication states

// Auth states
enum AuthState {
  idle,
  loading,
  captchaRequired,
  semesterSelection,
  dataDownloading,
  complete,
  error,
}

// Captcha types
enum CaptchaType { defaultCaptcha, reCaptcha }

// Page states
enum PageState { landing, login, home }

// User session
class UserSession {
  final String username;
  final String? studentName;
  final String? registrationNumber;
  final String? semesterName;
  final String? semesterID;
  final DateTime loginTime;
  final DateTime lastRefresh;

  UserSession({
    required this.username,
    this.studentName,
    this.registrationNumber,
    this.semesterName,
    this.semesterID,
    required this.loginTime,
    required this.lastRefresh,
  });

  // Check if session is valid
  bool get isValid {
    final now = DateTime.now();
    final sessionAge = now.difference(loginTime);
    return sessionAge.inHours < 24;
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'studentName': studentName,
      'registrationNumber': registrationNumber,
      'semesterName': semesterName,
      'semesterID': semesterID,
      'loginTime': loginTime.millisecondsSinceEpoch,
      'lastRefresh': lastRefresh.millisecondsSinceEpoch,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      username: json['username'] as String,
      studentName: json['studentName'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      semesterName: json['semesterName'] as String?,
      semesterID: json['semesterID'] as String?,
      loginTime: DateTime.fromMillisecondsSinceEpoch(json['loginTime'] as int),
      lastRefresh: DateTime.fromMillisecondsSinceEpoch(
        json['lastRefresh'] as int,
      ),
    );
  }
}
