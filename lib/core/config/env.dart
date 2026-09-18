import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment values loaded from `.env` via flutter_dotenv.
abstract final class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://tahfiz.onrender.com/';
}
