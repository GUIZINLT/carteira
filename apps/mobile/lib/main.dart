import 'package:carteira_core/carteira_core.dart';
import 'package:carteira_design_system/carteira_design_system.dart';
import 'package:flutter/material.dart';

import 'app_services.dart';
import 'features/auth/view/login_view.dart';
import 'features/home/view/home_view.dart';
import 'l10n/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CarteiraApp(services: await AppServices.create()));
}

/// Root of the widget tree. [MaterialApp] installs the theme, the
/// navigator, the text direction and the localizations that every widget
/// below reads through its [BuildContext].
class CarteiraApp extends StatelessWidget {
  const CarteiraApp({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: _AppEntry(services: services),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({required this.services});

  final AppServices services;

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late Future<bool> _restore;
  bool? _signedIn;

  @override
  void initState() {
    super.initState();
    _restore = _restoreSession();
  }

  Future<bool> _restoreSession() async {
    final restored = await widget.services.auth.restore();
    final session = restored.valueOrNull;
    if (session == null) return false;

    final profile = await widget.services.users.getProfile();
    if (profile.isOk) return true;
    if (profile.errorOrNull is UnauthorizedError) {
      await widget.services.auth.logout();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _restore,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final signedIn = _signedIn ?? snapshot.data ?? false;
      return signedIn
          ? HomeView(
              users: widget.services.users,
              transactions: widget.services.transactions,
              onSignOut: _signOut,
            )
          : LoginView(
              auth: widget.services.auth,
              onLogin: () => setState(() => _signedIn = true),
            );
    },
  );

  Future<void> _signOut() async {
    await widget.services.auth.logout();
    if (mounted) setState(() => _signedIn = false);
  }
}
