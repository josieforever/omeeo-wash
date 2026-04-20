class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();

  //global variable
  bool isAdmin = false;

  // Factory constructor returns the same instance every time
  factory AppConfig() {
    return _instance;
  }

  // Private constructor
  AppConfig._internal();

  // Method to update isAdmin
  void setAdmin(bool value) {
    isAdmin = value;
  }
}
