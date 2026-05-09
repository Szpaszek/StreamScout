class AppConfig {
  // IMPORTANT: Change this if running on an Android Emulator (use 'http://10.0.2.2:5000')
  static const String apiBaseUrl = 'http://10.0.2.2:5000';
  //static const String apiBaseUrl = 'http://194.117.224.17';
  static const String popularMoviesEndpoint = '/api/media/popular';
  static const String mediaDetailsEndpoint = '/api/media';
  static const String upcomingMoviesEndpoint = '/api/media/upcoming';
  static const String popularContentEndpoint = '/api/discover/popular';
  static const String latestContentEndpoint = '/api/discover/latest';
  static const String multiSearchEndpoint = '/api/search/multi';
}
