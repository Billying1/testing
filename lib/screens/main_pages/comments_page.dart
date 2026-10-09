import 'package:flutter/material.dart';

import '../../services/comments_service.dart';
import '../../services/preference_service.dart';
import '../widgets/brand_row.dart';

class CommentsPage extends StatefulWidget {
  final String stationId;
  final String stationName;

  const CommentsPage({super.key, required this.stationId, required this.stationName});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final comments = await CommentsService.getComments(widget.stationId);
    setState(() {
      _comments = comments.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final user = await PreferenceService.getUser();
    final author = user?.fullName ?? 'Anonymous';

    await CommentsService.addComment(widget.stationId, author, text);

    _ctrl.clear();
    await _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildComment(Map<String, dynamic> c) {
    final author = c['author'] ?? 'Anonymous';
    final text = c['text'] ?? '';
    final ts = DateTime.tryParse(c['timestamp'] ?? '') ?? DateTime.now();

    return ListTile(
      title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(text),
      trailing: Text(
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 12, color: Colors.black45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bình luận - ${widget.stationName}')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: BrandRow(),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('Chưa có bình luận nào.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _comments.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) =>
                            _buildComment(_comments[index]),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Viết bình luận...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _post,
                    child: const Text('Gửi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}