import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opennutritracker/generated/l10n.dart';

class StorageRecoveryApp extends StatelessWidget {
  const StorageRecoveryApp({
    required this.errorCode,
    required this.onRetry,
    super.key,
  });

  final String errorCode;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _StorageRecoveryScreen(errorCode: errorCode, onRetry: onRetry),
    );
  }
}

class _StorageRecoveryScreen extends StatefulWidget {
  const _StorageRecoveryScreen({
    required this.errorCode,
    required this.onRetry,
  });

  final String errorCode;
  final Future<void> Function() onRetry;

  @override
  State<_StorageRecoveryScreen> createState() => _StorageRecoveryScreenState();
}

class _StorageRecoveryScreenState extends State<_StorageRecoveryScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.storageRecoveryTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(s.storageRecoveryBody, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    s.storageRecoveryErrorCode(widget.errorCode),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    identifier: 'storage-recovery-retry',
                    child: FilledButton.icon(
                      onPressed: _retrying ? null : _retry,
                      icon: _retrying
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_outlined),
                      label: Text(s.storageRecoveryRetry),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
