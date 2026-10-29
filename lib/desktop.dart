import 'dart:convert';
import 'dart:io';

/// Shows a desktop notification on Linux; does nothing elsewhere.
Future<void> notify(String title, String body) async {
  if (!Platform.isLinux) return;
  try {
    await Process.run('notify-send', ['-a', 'Habitpp', '-u', 'critical', title, body]);
  } on ProcessException {
    // notify-send missing: the in-app banner still shows.
  }
}

File get _autostartFile => File('${Platform.environment['HOME']}/.config/autostart/habitpp.desktop');

bool get autostartSupported => Platform.isLinux;

bool autostartEnabled() => autostartSupported && _autostartFile.existsSync();

/// Adds or removes the login autostart entry pointing at the running binary.
Future<void> setAutostart(bool enabled) async {
  if (!autostartSupported) return;
  final file = _autostartFile;
  if (!enabled) {
    if (await file.exists()) await file.delete();
    return;
  }
  await file.parent.create(recursive: true);
  await file.writeAsString('''
[Desktop Entry]
Type=Application
Name=Habitpp
Comment=IELTS bosim ilovasi
Exec="${Platform.resolvedExecutable}"
Icon=habitpp
X-GNOME-Autostart-enabled=true
''');
}

/// Sends [text] via the Telegram Bot API; returns an error message or null.
Future<String?> sendTelegram(String token, String chatId, String text) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.postUrl(Uri.https('api.telegram.org', '/bot$token/sendMessage'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'chat_id': chatId, 'text': text}));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode == 200) return null;
    final description = (jsonDecode(body) as Map<String, dynamic>)['description'];
    return 'Telegram xatosi ${res.statusCode}: $description';
  } catch (e) {
    return "Telegramga ulanib bo'lmadi: $e";
  } finally {
    client.close();
  }
}
