import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'chat.dart';
import 'util.dart';

class Peer {
  final String id, name, phone;
  Peer(this.id, this.name, this.phone);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Peer> peers = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    sync();
  }

  void msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // Contact sync: match phone-book numbers with registered app users
  Future<void> sync() async {
    setState(() => loading = true);
    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        msg('Contacts permission is needed to find your family');
        return;
      }
      final cs = await FlutterContacts.getContacts(withProperties: true);
      final names = <String, String>{};
      for (final c in cs) {
        for (final p in c.phones) {
          final n = norm(p.number);
          if (n.length == 10) names[n] = c.displayName;
        }
      }
      final nums = names.keys.toList();
      final me = FirebaseAuth.instance.currentUser!.uid;
      final found = <Peer>[];
      for (var i = 0; i < nums.length; i += 10) {
        final q = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', whereIn: nums.sublist(i, min(i + 10, nums.length)))
            .get();
        for (final d in q.docs) {
          if (d.id == me) continue;
          final data = d.data();
          final ph = data['phone'] as String;
          found.add(Peer(d.id, names[ph] ?? data['name'] as String, ph));
        }
      }
      found.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() => peers = found);
    } catch (e) {
      msg('Contact sync needs internet. Showing last list.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kawin Vinu', style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            IconButton(icon: const Icon(Icons.sync), tooltip: 'Sync contacts', onPressed: sync),
            IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log out',
                onPressed: () => FirebaseAuth.instance.signOut()),
          ],
        ),
        body: loading && peers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : peers.isEmpty
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'No family found yet.\nAsk them to sign up, then tap sync.',
                            textAlign: TextAlign.center)))
                : ListView(
                    children: peers
                        .map((p) => ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF00A884),
                                  child: Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase())),
                              title: Text(p.name),
                              subtitle: Text(p.phone),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ChatPage(peerId: p.id, peerName: p.name))),
                            ))
                        .toList()),
      );
}
