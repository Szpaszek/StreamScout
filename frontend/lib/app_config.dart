import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // local server
  //static const String apiBaseUrl = 'http://10.0.2.2:5000';
  // online server
  static const String apiBaseUrl = 'http://194.117.224.17';
  static const String popularMoviesEndpoint = '/api/media/popular';
  static const String mediaDetailsEndpoint = '/api/media';
  static const String upcomingMoviesEndpoint = '/api/media/upcoming';
  static const String popularContentEndpoint = '/api/discover/popular';
  static const String latestContentEndpoint = '/api/discover/latest';
  static const String multiSearchEndpoint = '/api/search/multi';
  static const String personEndpoint = '/api/person';

  static final String appToken = dotenv.env['APP_TOKEN'] ?? 'App token not found.';

    static Map<String, String> getRequestHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-StreamScout-Token': appToken,
    };
  }
}
