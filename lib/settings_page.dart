import 'package:flutter/material.dart';

import 'desktop.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final _token = TextEditingController(text: widget.state.settings.telegramToken);
  late final _chat = TextEditingController(text: widget.state.settings.telegramChatId);
  bool _showToken = false;
  bool _testing = false;
  bool _autostart = autostartEnabled();

  @override
  void dispose() {
    _token.dispose();
    _chat.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _saveTelegram() async {
    await widget.state.updateSettings((s) {
      s.telegramToken = _token.text.trim();
      s.telegramChatId = _chat.text.trim();
    });
    _toast('Saqlandi');
  }

  Future<void> _test() async {
    await _saveTelegram();
    setState(() => _testing = true);
    final error = await sendTelegram(
      _token.text.trim(),
      _chat.text.trim(),
      '✅ Habitpp ulandi. Har kuni 20:59 da hisobot keladi.',
    );
    if (!mounted) return;
    setState(() => _testing = false);
    _toast(error ?? 'Sinov xabari yuborildi ✅');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.settings;
    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth >= 700 ? 32.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sozlamalar',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('BOSIM'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('20:45 eslatma'),
                          subtitle: const Text("Kuniga bitta bildirishnoma — faqat kun yopilmagan bo'lsa"),
                          value: s.remindAt2045,
                          onChanged: (v) => widget.state.updateSettings((s) => s.remindAt2045 = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('20:59 da Telegram kanalga avtomatik hisobot'),
                          subtitle: Text(
                            s.telegramReady
                                ? 'Kanalingizdagi odamlar natijani ko\'radi — tashqi nazorat'
                                : 'Avval pastda Telegram botni ulang',
                          ),
                          value: s.autoReport && s.telegramReady,
                          onChanged: s.telegramReady
                              ? (v) => widget.state.updateSettings((s) => s.autoReport = v)
                              : null,
                        ),
                        if (autostartSupported)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Kompyuter yonganda ochilsin'),
                            subtitle: const Text(
                              "Ubuntu'ga kirishingiz bilan bugungi vazifa va qarzlar ko'rinadi",
                            ),
                            value: _autostart,
                            onChanged: (v) async {
                              await setAutostart(v);
                              setState(() => _autostart = autostartEnabled());
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('TELEGRAM HISOBOT'),
                        const Text(
                          "1) @BotFather'da bot oching (yoki DoLoop bot tokenini ishlating). "
                          '2) Botni kanalingizga admin qiling. '
                          "3) Kanal ID'sini kiriting: @kanal_nomi yoki -100… raqami.",
                          style: TextStyle(color: Palette.muted, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _token,
                          obscureText: !_showToken,
                          decoration: InputDecoration(
                            labelText: 'Bot token',
                            suffixIcon: IconButton(
                              icon: Icon(_showToken ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showToken = !_showToken),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _chat,
                          decoration: const InputDecoration(labelText: 'Kanal yoki chat ID'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(onPressed: _saveTelegram, child: const Text('Saqlash')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _testing ? null : _test,
                                child: Text(_testing ? 'Yuborilmoqda…' : 'Sinov xabari'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Token faqat shu kompyuterda saqlanadi, GitHub\'ga tushmaydi.',
                          style: TextStyle(color: Palette.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle("MA'LUMOTLAR"),
                        SelectableText(
                          widget.state.file?.path ?? 'Xotirada (saqlanmaydi)',
                          style: const TextStyle(color: Palette.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.state.logs.length} ta yozuv',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
