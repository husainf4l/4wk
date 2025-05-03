import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample chat data - in a real app, this would come from a database
    final List<Map<String, dynamic>> chats = [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ai Actions',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Search Box
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                onChanged: (value) {
                  // Search functionality would go here
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  chats.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return _buildChatItem(context, chat, theme);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with support or service centers',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    Map<String, dynamic> chat,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.snackbar(
            'Chat',
            'Opening chat with ${chat['name']}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(chat['avatar']),
                onBackgroundImageError: (_, __) {},
                child:
                    NetworkImage(chat['avatar']).toString().isEmpty
                        ? Text(
                          chat['name'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 20),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat['name'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight:
                                chat['unread'] > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        Text(
                          _getTimeAgo(chat['time']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage'],
                            style: TextStyle(
                              color:
                                  chat['unread'] > 0
                                      ? Colors.black87
                                      : Colors.grey[600],
                              fontWeight:
                                  chat['unread'] > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat['unread'] > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat['unread'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final duration = DateTime.now().difference(time);

    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h';
    } else if (duration.inDays < 7) {
      return '${duration.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
