import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});
  @override State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  int _tab = 0;
  final _search = TextEditingController();
  final List<_DemoConversation> _chats = [
    _DemoConversation('BIIC CHAT', 'Bienvenue sur BIIC CHAT', true, true),
    _DemoConversation('Jean', 'Salut, comment vas-tu ?', false, false),
    _DemoConversation('Équipe BIIC', 'La réunion est à 15h.', false, false),
  ];

  Future<void> _newChat() async {
    final permission = await FlutterContacts.permissions.request(PermissionType.readWrite);
    if (permission != PermissionStatus.granted) {
      if (mounted) _snack('Autorisation des contacts refusée.');
      return;
    }
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            const ListTile(title: Text('Nouveau chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            const Divider(height: 1),
            Expanded(child: contacts.isEmpty
              ? const Center(child: Text('Aucun contact disponible.'))
              : ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = contacts[i];
                    final rawName = c.displayName ?? '';
                    final name = rawName.trim().isEmpty ? 'Contact' : rawName;
                    return ListTile(
                      leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
                      title: Text(name),
                      subtitle: Text(c.phones.isEmpty ? 'Aucun numéro' : c.phones.first.number),
                      onTap: () {
                        Navigator.pop(context);
                        _openChat(name);
                      },
                    );
                  },
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _attachments() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(child: Wrap(children: [
        const ListTile(title: Text('Partager', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photos et vidéos'), onTap: () => Navigator.pop(context, 'media')),
        ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Appareil photo'), onTap: () => Navigator.pop(context, 'camera')),
        ListTile(leading: const Icon(Icons.attach_file), title: const Text('Document'), onTap: () => Navigator.pop(context, 'file')),
        ListTile(leading: const Icon(Icons.contacts_outlined), title: const Text('Contact'), onTap: () => Navigator.pop(context, 'contact')),
      ])),
    );
    if (!mounted || action == null) return;
    try {
      if (action == 'media') {
        final x = await ImagePicker().pickMedia();
        if (x != null) _snack('Média sélectionné : ${x.name}');
      } else if (action == 'camera') {
        final x = await ImagePicker().pickImage(source: ImageSource.camera);
        if (x != null) _snack('Photo sélectionnée : ${x.name}');
      } else if (action == 'file') {
        final files = await FilePicker.pickFiles();
        if (files.isNotEmpty) _snack('Document sélectionné : ' + files.first.name);
      } else if (action == 'contact') {
        await _newChat();
      }
    } catch (e) {
      if (mounted) _snack('Accès impossible : $e');
    }
  }

  void _openChat(String name) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DemoChatPage(title: name)));
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = _chats.where((c) => c.name.toLowerCase().contains(query) || c.preview.toLowerCase().contains(query)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIIC CHAT', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined), tooltip: 'Caméra'),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search), tooltip: 'Rechercher'),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'contacts') _newChat(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'contacts', child: Text('Importer des contacts')),
              PopupMenuItem(value: 'settings', child: Text('Paramètres')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher une discussion',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
              ),
            ),
          ),
          Expanded(child: filtered.isEmpty
            ? const Center(child: Text('Aucune discussion'))
            : ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(radius: 27, child: Text(c.name.substring(0, 1))),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(c.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(c.online ? 'en ligne' : '10:32', style: TextStyle(fontSize: 11, color: c.online ? Theme.of(context).colorScheme.primary : null)),
                      const SizedBox(height: 4),
                      if (i == 1) const CircleAvatar(radius: 10, child: Text('2', style: TextStyle(fontSize: 10))),
                    ]),
                    onTap: () => _openChat(c.name),
                  );
                },
              )),
        ]),
        const _DemoStatusPage(),
        const _DemoCallsPage(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Discussions'),
          NavigationDestination(icon: Icon(Icons.circle_outlined), selectedIcon: Icon(Icons.circle), label: 'Statuts'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Appels'),
        ],
      ),
      floatingActionButton: _tab == 0 ? FloatingActionButton(onPressed: _newChat, child: const Icon(Icons.chat_rounded)) : null,
    );
  }

  @override void dispose() { _search.dispose(); super.dispose(); }
}

class _DemoConversation {
  final String name, preview;
  final bool online, pinned;
  const _DemoConversation(this.name, this.preview, this.online, this.pinned);
}

class _DemoStatusPage extends StatelessWidget {
  const _DemoStatusPage();
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [
    ListTile(leading: CircleAvatar(child: Icon(Icons.add)), title: Text('Mon statut', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Ajouter une photo ou une vidéo')),
    SizedBox(height: 12), Text('Mises à jour récentes', style: TextStyle(fontWeight: FontWeight.w800)),
    ListTile(leading: CircleAvatar(child: Text('J')), title: Text('Jean'), subtitle: Text('Aujourd’hui, 09:41')),
    ListTile(leading: CircleAvatar(child: Text('B')), title: Text('BIIC CHAT'), subtitle: Text('Aujourd’hui, 08:20')),
  ]);
}

class _DemoCallsPage extends StatelessWidget {
  const _DemoCallsPage();
  @override Widget build(BuildContext context) => ListView(children: const [
    ListTile(leading: CircleAvatar(child: Text('J')), title: Text('Jean'), subtitle: Text('Appel vocal • Aujourd’hui, 09:20'), trailing: Icon(Icons.call_outlined)),
    ListTile(leading: CircleAvatar(child: Text('B')), title: Text('BIIC CHAT'), subtitle: Text('Appel vidéo • Hier'), trailing: Icon(Icons.videocam_outlined)),
  ]);
}

class DemoChatPage extends StatefulWidget {
  final String title;
  const DemoChatPage({super.key, required this.title});
  @override State<DemoChatPage> createState() => _DemoChatPageState();
}

class _DemoChatPageState extends State<DemoChatPage> {
  final _controller = TextEditingController();
  final List<_LocalMessage> _messages = [
    const _LocalMessage('Bonjour 👋', false),
    const _LocalMessage('Salut ! Bienvenue sur BIIC CHAT.', true),
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add(_LocalMessage(text, true)); _controller.clear(); });
  }

  Future<void> _attach() async {
    final action = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photos et vidéos'), onTap: () => Navigator.pop(context, 'media')),
      ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Caméra'), onTap: () => Navigator.pop(context, 'camera')),
      ListTile(leading: const Icon(Icons.insert_drive_file_outlined), title: const Text('Document'), onTap: () => Navigator.pop(context, 'file')),
      ListTile(leading: const Icon(Icons.contacts_outlined), title: const Text('Contact'), onTap: () => Navigator.pop(context, 'contact')),
    ])));
    if (!mounted || action == null) return;
    try {
      if (action == 'media') {
        final x = await ImagePicker().pickMedia();
        if (x != null) setState(() => _messages.add(_LocalMessage('📷 ${x.name}', true)));
      } else if (action == 'camera') {
        final x = await ImagePicker().pickImage(source: ImageSource.camera);
        if (x != null) setState(() => _messages.add(_LocalMessage('📷 Photo : ${x.name}', true)));
      } else if (action == 'file') {
        final files = await FilePicker.pickFiles();
        if (files.isNotEmpty) setState(() => _messages.add(_LocalMessage('📎 ' + files.first.name, true)));
      } else {
        final permission = await FlutterContacts.permissions.request(PermissionType.readWrite);
        if (permission != PermissionStatus.granted) throw Exception('Accès aux contacts refusé');
        final contacts = await FlutterContacts.getAll(properties: {ContactProperty.name, ContactProperty.phone});
        if (contacts.isNotEmpty && mounted) {
          final contactName = contacts.first.displayName ?? 'Contact';
          setState(() => _messages.add(_LocalMessage('👤 Contact : ' + contactName, true)));
        }
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        const CircleAvatar(radius: 18, child: Text('B')),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Text('en ligne', style: TextStyle(fontSize: 11)),
        ]),
      ]),
      actions: const [Icon(Icons.videocam_outlined), SizedBox(width: 14), Icon(Icons.call_outlined), SizedBox(width: 12)],
    ),
    body: Column(children: [
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final m = _messages[i];
          return Align(alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
            decoration: BoxDecoration(color: m.mine ? const Color(0xFFD71920) : Colors.white, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(m.mine ? 16 : 4), bottomRight: Radius.circular(m.mine ? 4 : 16))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(m.text, style: TextStyle(color: m.mine ? Colors.white : Colors.black87))),
              const SizedBox(width: 8), Text('10:32', style: TextStyle(fontSize: 10, color: m.mine ? Colors.white70 : Colors.black45)),
            ]),
          ));
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(8, 5, 8, 8), child: Row(children: [
        IconButton(onPressed: _attach, icon: const Icon(Icons.add_circle_outline)),
        Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Message'))),
        const SizedBox(width: 6),
        IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
      ]))),
    ]),
  );

  @override void dispose() { _controller.dispose(); super.dispose(); }
}

class _LocalMessage {
  final String text; final bool mine;
  const _LocalMessage(this.text, this.mine);
}
