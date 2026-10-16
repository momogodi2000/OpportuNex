import 'dart:io';

/// Optional launch at session start, minimised to the tray (EF-13.09). Off unless the user turns it on.
///
/// * Windows: a value under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` (current user only).
/// * Linux: an XDG autostart entry in `~/.config/autostart/`.
/// Other platforms report it as unsupported.
class Autostart {
  Autostart({String? executable, Map<String, String>? environment, this.run = Process.run})
      : executable = executable ?? Platform.resolvedExecutable,
        _env = environment ?? Platform.environment;

  final String executable;
  final Map<String, String> _env;
  final Future<ProcessResult> Function(String, List<String>) run;

  static const valueName = 'Opportunex';
  static const runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const flag = '--minimized';

  bool get supported => Platform.isWindows || Platform.isLinux;

  /// Command stored in the registry: quoted path (it may contain spaces) plus the minimised flag.
  String get windowsCommand => '"$executable" $flag';

  List<String> windowsEnableArgs() => ['add', runKey, '/v', valueName, '/t', 'REG_SZ', '/d', windowsCommand, '/f'];
  List<String> windowsDisableArgs() => ['delete', runKey, '/v', valueName, '/f'];
  List<String> windowsQueryArgs() => ['query', runKey, '/v', valueName];

  File get linuxEntry {
    final config = _env['XDG_CONFIG_HOME'] ?? '${_env['HOME']}/.config';
    return File('$config/autostart/opportunex.desktop');
  }

  String linuxDesktopEntry() => [
        '[Desktop Entry]',
        'Type=Application',
        'Name=Opportunex',
        'Exec="$executable" $flag',
        'X-GNOME-Autostart-enabled=true',
        '',
      ].join('\n');

  Future<bool> isEnabled() async {
    if (Platform.isWindows) {
      final r = await run('reg', windowsQueryArgs());
      return r.exitCode == 0 && '${r.stdout}'.contains(valueName);
    }
    if (Platform.isLinux) return linuxEntry.existsSync();
    return false;
  }

  Future<void> setEnabled(bool enabled) async {
    if (Platform.isWindows) {
      final r = await run('reg', enabled ? windowsEnableArgs() : windowsDisableArgs());
      // Deleting a value that does not exist is not an error for the user.
      if (r.exitCode != 0 && enabled) throw ProcessException('reg', windowsEnableArgs(), '${r.stderr}', r.exitCode);
    } else if (Platform.isLinux) {
      final f = linuxEntry;
      if (enabled) {
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(linuxDesktopEntry());
      } else if (f.existsSync()) {
        f.deleteSync();
      }
    }
  }
}
