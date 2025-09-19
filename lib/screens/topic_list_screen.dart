import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../services/db_helper.dart';
import 'theory_screen.dart'; // Import màn hình hiển thị câu hỏi

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final rawTopics = await DBHelper().getTopics();
    setState(() {
      _topics = rawTopics.map((map) => Topic.fromMap(map)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học lý thuyết'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? const Center(child: Text('Không có chương nào để học.'))
              : ListView.builder(
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          topic.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(topic.description),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Điều hướng đến màn hình hiển thị câu hỏi của chương
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TheoryScreen(
                                topicId: topic.id,
                                topicTitle: topic.title,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}