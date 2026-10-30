
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const NxFApp());
}

const bg = Color(0xFF080610);
const panel = Color(0xFF151025);
const purple = Color(0xFFAA55FF);
const cyan = Color(0xFF45D9FF);

class NxFApp extends StatelessWidget {
  const NxFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NxF AI V1',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: purple,
          secondary: cyan,
          surface: panel,
        ),
      ),
      home: const NxFHome(),
    );
  }
}

class NxFHome extends StatefulWidget {
  const NxFHome({super.key});

  @override
  State<NxFHome> createState() => _NxFHomeState();
}

class _NxFHomeState extends State<NxFHome> {
  int page = 0;
  String backendUrl = '';
  final input = TextEditingController();
  final urlInput = TextEditingController();
  final scroll = ScrollController();

  bool loading = false;
  final List<Map<String, String>> messages = [];
  final List<String> history = [];

  Future<String> askAI(String message) async {
    if (backendUrl.trim().isEmpty) {
      return 'Set your backend URL in Settings first.';
    }

    final client = HttpClient();

    try {
      final uri = Uri.parse(
        '${backendUrl.trim().replaceAll(RegExp(r'/$'), '')}/api/chat',
      );

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are NxF AI, a helpful assistant. Help with general questions, Flutter, and Roblox Luau coding.'
          },
          ...messages.map((m) => {
                'role': m['role'],
                'content': m['content'],
              }),
          {'role': 'user', 'content': message},
        ],
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return 'Server error ${response.statusCode}: $body';
      }

      final data = jsonDecode(body);
      return data['reply']?.toString() ??
          data['choices']?[0]?['message']?['content']?.toString() ??
          'The server returned an unexpected response.';
    } catch (e) {
      return 'Connection failed. Check your backend URL and server.';
    } finally {
      client.close();
    }
  }

  Future<void> sendMessage() async {
    final text = input.text.trim();
    if (text.isEmpty || loading) return;

    input.clear();

    setState(() {
      messages.add({'role': 'user', 'content': text});
      loading = true;
    });

    final reply = await askAI(text);

    if (!mounted) return;

    setState(() {
      messages.add({'role': 'assistant', 'content': reply});
      history.insert(0, text);
      loading = false;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void newChat() {
    setState(() {
      messages.clear();
      page = 1;
    });
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: panel,
        border: Border(
          bottom: BorderSide(color: purple, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [purple, Color(0xFF6030B0)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXUS X',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'FANTRICK / AI V1',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.circle, color: Colors.green, size: 9),
          const SizedBox(width: 6),
          const Text('READY', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 15),
        const Text(
          'WELCOME TO NxF',
          style: TextStyle(
            color: purple,
            letterSpacing: 3,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your AI.\nYour creativity.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'NEXUS X FANTRICK — MADE BY KINGSLEY',
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 30),
        featureCard(
          Icons.chat_bubble_outline,
          'AI CHAT',
          'Talk with your AI assistant.',
          () => setState(() => page = 1),
        ),
        featureCard(
          Icons.code,
          'LUAU ASSISTANT',
          'Get help writing Roblox scripts.',
          () {
            input.text = 'Help me with Roblox Luau: ';
            setState(() => page = 1);
          },
        ),
        featureCard(
          Icons.history,
          'CHAT HISTORY',
          'View your recent prompts.',
          () => setState(() => page = 2),
        ),
        featureCard(
          Icons.settings,
          'SETTINGS',
          'Configure your AI connection.',
          () => setState(() => page = 3),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: purple.withOpacity(.4)),
          ),
          child: const Text(
            'NxF AI V1\nPowered by your connected AI backend.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget featureCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) {
    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: purple.withOpacity(.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(icon, color: purple, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        onTap: action,
      ),
    );
  }

  Widget chatPage() {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 55, color: purple),
                      SizedBox(height: 12),
                      Text(
                        'NxF AI IS READY',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Send a message to begin.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length + (loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'NxF AI is thinking...',
                          style: TextStyle(color: cyan),
                        ),
                      );
                    }

                    final item = messages[index];
                    final user = item['role'] == 'user';

                    return Align(
                      alignment: user
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 310),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: user
                              ? const Color(0xFF38205C)
                              : panel,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: user ? purple : Colors.white12,
                          ),
                        ),
                        child: SelectableText(
                          item['content'] ?? '',
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: panel,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Message NxF AI...',
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: loading ? null : sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget historyPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'RECENT PROMPTS',
          style: TextStyle(
            color: purple,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        if (history.isEmpty)
          const Text(
            'No recent prompts yet.',
            style: TextStyle(color: Colors.white54),
          ),
        ...history.map(
          (item) => Card(
            color: panel,
            child: ListTile(
              leading: const Icon(Icons.message, color: cyan),
              title: Text(item),
              onTap: () {
                input.text = item;
                setState(() => page = 1);
              },
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => history.clear()),
          child: const Text('CLEAR HISTORY'),
        ),
      ],
    );
  }

  Widget settingsPage() {
    urlInput.text = backendUrl;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        const Text('AI BACKEND URL'),
        const SizedBox(height: 8),
        TextField(
          controller: urlInput,
          decoration: const InputDecoration(
            hintText: 'https://your-backend.example.com',
            filled: true,
            fillColor: panel,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            setState(() {
              backendUrl = urlInput.text.trim();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backend URL updated')),
            );
          },
          child: const Text('SAVE BACKEND URL'),
        ),
        const SizedBox(height: 25),
        const Text(
          'SECURITY',
          style: TextStyle(color: cyan, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Keep your AI provider API key on your backend server. '
          'Never paste your private API key into this app.',
          style: TextStyle(color: Colors.white60, height: 1.5),
        ),
        const SizedBox(height: 25),
        const Text(
          'NxF AI V1\nMade by Kingsley',
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'AI Chat', 'History', 'Settings'];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: SafeArea(child: header()),
      ),
      body: IndexedStack(
        index: page,
        children: [
          homePage(),
          chatPage(),
          historyPage(),
          settingsPage(),
        ],
      ),
      floatingActionButton: page == 1
          ? FloatingActionButton.small(
              backgroundColor: purple,
              onPressed: newChat,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        backgroundColor: panel,
        indicatorColor: purple.withOpacity(.25),
        onDestinationSelected: (index) {
          setState(() => page = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
