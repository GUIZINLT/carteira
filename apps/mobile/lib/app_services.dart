import 'dart:convert';
import 'dart:io';

import 'package:carteira_core/carteira_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wires the app's data sources to the framework independent Core contracts.
class AppServices {
  const AppServices({
    required this.auth,
    required this.users,
    required this.transactions,
  });

  final AuthRepository auth;
  final UserRepository users;
  final TransactionRepository transactions;

  static Future<AppServices> create() async {
    final preferences = await SharedPreferences.getInstance();
    final storage = _PreferencesSessionStorage(preferences);
    final client = ApiClient(baseUrl: _baseUrl);
    return AppServices(
      auth: RemoteAuthRepository(client: client, storage: storage),
      users: RemoteUserRepository(client: client),
      transactions: RemoteTransactionRepository(client: client),
    );
  }

  static String get _baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }
}

class _PreferencesSessionStorage implements SessionStorage {
  _PreferencesSessionStorage(this._preferences);

  static const _key = 'carteira.session';
  final SharedPreferences _preferences;

  @override
  Future<Session?> read() async {
    final encoded = _preferences.getString(_key);
    if (encoded == null) return null;
    try {
      return Session.fromJson(asJson(jsonDecode(encoded)));
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(Session session) async {
    await _preferences.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
