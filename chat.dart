import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String peerId, peerName;
  const ChatPage({super.key, required this.peerId, required this.peerName});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final me = FirebaseAuth.instance.currentUser!.uid;
  final ctl = TextEditingController();
  late final String chatId = ([me, widget.peerId]..sort()).join('_');
  late final CollectionReference<Map<String, dynamic>> col = FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages');

  // Works offline: Firestore keeps it on the phone and sends when network returns
  void send() {
    final t = ctl.text.trim();
    if (t.isEmpty) return;
    ctl.clear();
    col.add({'from': me, 'text': t, 'ts': FieldValue.serverTimestamp(), 'read': false});
  }

  Widget tick(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    if (d.metadata.hasPendingWrites) {
      return const Icon(Icons.access_time, size: 13, color: Colors.white54);
    }
    final read = d.data()['read'] == true;
    return Icon(read ? Icons.done_all : Icons.done,
        size: 16, color: read ? const Color(0xFF53BDEB) : Colors.white);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.peerName)),
        body: Column(children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: col.orderBy('ts').snapshots(includeMetadataChanges: true),
              builder: (c, s) {
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                final docs = s.data!.docs;
                final unread =
                    docs.where((d) => d.data()['from'] != me && d.data()['read'] != true).toList();
                if (unread.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final b = FirebaseFirestore.instance.batch();
                    for (final d in unread) {
                      b.update(d.reference, {'read': true});
                    }
                    b.commit();
                  });
                }
                final list = docs.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final d = list[i];
                    final m = d.data();
                    final mine = m['from'] == me;
                    final ts = m['ts'] as Timestamp?;
                    final time = ts == null ? '' : TimeOfDay.fromDateTime(ts.toDate()).format(context);
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFF005C4B) : const Color(0xFF202C33),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Align(alignment: Alignment.centerLeft, child: Text(m['text'] as String)),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(time, style: const TextStyle(fontSize: 10.5, color: Colors.white54)),
                            if (mine) ...[const SizedBox(width: 4), tick(d)],
                          ]),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: ctl,
                    onSubmitted: (_) => send(),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      filled: true,
                      fillColor: const Color(0xFF202C33),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                    radius: 23,
                    backgroundColor: const Color(0xFF00A884),
                    child: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF06251E)), onPressed: send)),
              ]),
            ),
          ),
        ]),
      );
}
