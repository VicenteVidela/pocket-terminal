import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xterm/xterm.dart';

void main() => runApp(const PocketTerminal());

class PocketTerminal extends StatelessWidget {
  const PocketTerminal({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pocket Terminal',
    theme: ThemeData.dark(useMaterial3: true),
    home: const ConnectPage(),
  );
}

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});
  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final host = TextEditingController();
  final port = TextEditingController(text: '22');
  final user = TextEditingController();
  final password = TextEditingController();
  Terminal terminal = Terminal(maxLines: 10000);
  final storage = const FlutterSecureStorage();
  SSHClient? client;
  SSHSession? session;
  bool connecting = false;
  String? error;

  Future<bool> approve(String hostname, String type, String fingerprint) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Verify host key'),
            content: SelectableText(
              'Compare this fingerprint with a trusted source before accepting.\n\n$hostname\n$type\n$fingerprint',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Reject'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Accept'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> connect() async {
    final hostname = host.text.trim();
    final username = user.text.trim();
    final portNumber = int.tryParse(port.text);
    if (hostname.isEmpty ||
        username.isEmpty ||
        password.text.isEmpty ||
        portNumber == null ||
        portNumber < 1 ||
        portNumber > 65535) {
      setState(
        () => error = 'Enter a host, valid port, username and password.',
      );
      return;
    }
    final enteredPassword = password.text;
    setState(() {
      connecting = true;
      error = null;
      terminal = Terminal(maxLines: 10000);
    });
    SSHClient? openedClient;
    try {
      final socket = await SSHSocket.connect(
        hostname,
        portNumber,
        timeout: const Duration(seconds: 12),
      );
      if (!mounted) {
        socket.destroy();
        return;
      }
      final pinKey = 'hostkey:${Uri.encodeComponent(hostname)}:$portNumber';
      openedClient = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => enteredPassword,
        onVerifyHostKey: (type, bytes) async {
          final fingerprint = utf8.decode(bytes);
          final identity = '$type $fingerprint';
          final saved = await storage.read(key: pinKey);
          if (saved != null) {
            if (saved != identity) {
              throw StateError('Host key changed. Connection refused.');
            }
            return true;
          }
          if (!await approve(hostname, type, fingerprint)) return false;
          await storage.write(key: pinKey, value: identity);
          return true;
        },
      );
      client = openedClient;
      final shell = await openedClient.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );
      if (!mounted) {
        shell.close();
        openedClient.close();
        return;
      }
      session = shell;
      password.clear();
      terminal.onOutput = (text) =>
          shell.stdin.add(Uint8List.fromList(utf8.encode(text)));
      terminal.onResize = (w, h, pw, ph) => shell.resizeTerminal(w, h, pw, ph);
      shell.resizeTerminal(terminal.viewWidth, terminal.viewHeight);
      unawaited(
        utf8.decoder.bind(shell.stdout).forEach(terminal.write).catchError((
          Object e,
        ) {
          terminal.write('\r\nConnection error: $e\r\n');
        }),
      );
      unawaited(
        utf8.decoder.bind(shell.stderr).forEach(terminal.write).catchError((
          Object e,
        ) {
          terminal.write('\r\nConnection error: $e\r\n');
        }),
      );
      unawaited(
        shell.done.then((_) {
          if (mounted && identical(session, shell)) {
            setState(() {
              session = null;
              terminal.onOutput = null;
              terminal.onResize = null;
              client?.close();
              client = null;
              error = 'Session ended.';
            });
          }
        }),
      );
      setState(() {});
    } catch (e) {
      openedClient?.close();
      client = null;
      password.clear();
      if (mounted) setState(() => error = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => connecting = false);
    }
  }

  void disconnect() {
    final oldSession = session;
    setState(() {
      session = null;
      terminal.onOutput = null;
      terminal.onResize = null;
      error = 'Disconnected.';
    });
    oldSession?.close();
    client?.close();
    client = null;
  }

  @override
  void dispose() {
    session?.close();
    client?.close();
    host.dispose();
    port.dispose();
    user.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pocket Terminal'),
      actions: [
        if (session != null)
          IconButton(
            tooltip: 'Disconnect',
            onPressed: disconnect,
            icon: const Icon(Icons.link_off),
          ),
      ],
    ),
    body: session != null
        ? TerminalView(terminal, autofocus: true)
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Connect to an SSH server. Passwords are not saved.'),
              TextField(
                controller: host,
                decoration: const InputDecoration(labelText: 'Hostname'),
              ),
              TextField(
                controller: port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
              TextField(
                controller: user,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(error!),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: connecting ? null : connect,
                child: Text(connecting ? 'Connecting…' : 'Connect'),
              ),
            ],
          ),
  );
}
