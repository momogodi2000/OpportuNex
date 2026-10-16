import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:logging/logging.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/api/engine_events.dart';
import '../../core/engine/engine_supervisor.dart';
import '../../core/prefs/ui_prefs.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../monitors/monitors_page.dart';

final _log = Logger('desktop');

/// Native toasts for engine notifications (EF-13.04) and the system-tray presence that keeps monitors
/// and deadline reminders running while the window is hidden (EF-13.06). Every native call is optional:
/// a desktop without a tray or notification service still gets the in-app notification list.
class DesktopIntegration with TrayListener, WindowListener {
  DesktopIntegration(this.container);

  final ProviderContainer container;
  bool _trayReady = false;
  bool get trayReady => _trayReady;
  bool _quitting = false;
  bool _hintShown = false;

  AppLocalizations get _l => lookupAppLocalizations(container.read(uiPrefsProvider).locale);

  Future<void> start() async {
    windowManager.addListener(this);
    try {
      await localNotifier.setup(appName: 'Opportunex');
    } on Object catch (e) {
      _log.warning('native notifications unavailable: $e');
    }
    try {
      await trayManager.setIcon(Platform.isWindows ? 'assets/images/tray_icon.ico' : 'assets/images/app_icon.png');
      await trayManager.setToolTip('Opportunex');
      trayManager.addListener(this);
      _trayReady = true;
      await _buildMenu();
      container.listen(uiPrefsProvider.select((p) => p.locale), (_, _) => unawaited(_buildMenu()));
    } on Object catch (e) {
      _log.warning('system tray unavailable: $e');
    }
    container.listen<AsyncValue<EngineEvent>>(engineEventsProvider, (_, next) => next.whenData(_onEvent));
  }

  Future<void> _buildMenu() => trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'open', label: _l.trayOpen),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: _l.trayQuit),
      ]));

  void _onEvent(EngineEvent e) {
    if (e.type != 'notification') return;
    container.invalidate(notificationsProvider);
    final title = e.data['title'];
    if (e.data['native'] != true || title is! String) return;
    final link = deepLinkFor(e.data['payload']);
    final toast = LocalNotification(title: title, body: e.data['body'] as String?)..onClick = () => unawaited(_open(link));
    unawaited(toast.show().catchError((Object err) => _log.warning('toast failed: $err')));
  }

  Future<void> _open([String? location]) async {
    await windowManager.show();
    await windowManager.focus();
    if (location != null) container.read(routerProvider).go(location);
  }

  /// Stops the engine cleanly (WAL checkpoint, job state persisted) and exits; never hangs.
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    try {
      await container.read(engineSupervisorProvider.notifier).stop().timeout(const Duration(seconds: 6));
    } on Object {
      // Closing must never hang.
    }
    if (_trayReady) {
      try {
        await trayManager.destroy();
      } on Object {
        // Already gone.
      }
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<void> onWindowClose() async {
    if (_trayReady && !_quitting && container.read(uiPrefsProvider).closeToTray) {
      await windowManager.hide();
      if (!_hintShown) {
        _hintShown = true;
        unawaited(LocalNotification(title: 'Opportunex', body: _l.trayStillRunning).show().catchError((Object _) {}));
      }
      return;
    }
    await quit();
  }

  @override
  void onTrayIconMouseDown() => unawaited(_open());

  @override
  void onTrayIconRightMouseDown() => unawaited(trayManager.popUpContextMenu());

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        unawaited(_open());
      case 'quit':
        unawaited(quit());
    }
  }
}

/// In-app destination for a notification payload, most specific first.
String? deepLinkFor(Object? payload) {
  if (payload is! Map) return null;
  if (payload['saved_id'] is String) return '/saved/${payload['saved_id']}';
  if (payload['run_id'] is String) return '/search?run=${payload['run_id']}';
  if (payload['opportunity_id'] is String) return '/opportunities/${payload['opportunity_id']}';
  if (payload['source_id'] is String) return '/sources';
  if (payload['monitor_id'] is String) return '/monitors';
  return null;
}
