import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class JobOrderRequestHistoryScreen extends StatefulWidget {
  final String jobOrderId;
  final String carMake;
  final String carModel;
  final String carPlate;

  const JobOrderRequestHistoryScreen({
    super.key,
    required this.jobOrderId,
    required this.carMake,
    required this.carModel,
    required this.carPlate,
  });

  @override
  State<JobOrderRequestHistoryScreen> createState() =>
      _JobOrderRequestHistoryScreenState();
}

class _JobOrderRequestHistoryScreenState
    extends State<JobOrderRequestHistoryScreen> {
  final TextEditingController _noteController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _sending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final userName = _authController.currentUser?.displayName ?? 'Unknown';
      final noteData = {
        'text': note,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': userName,
      };
      await FirebaseFirestore.instance
          .collection('jobOrders')
          .doc(widget.jobOrderId)
          .collection('requestNotes')
          .add(noteData);
      _noteController.clear();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send note',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(8),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Communication',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.carMake} ${widget.carModel} • ${widget.carPlate}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('jobOrders')
                        .doc(widget.jobOrderId)
                        .collection('requestNotes')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 3,
                      ),
                    );
                  }
                  final notes = snapshot.data?.docs ?? [];
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 48,
                            color: colorScheme.outline.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notes yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    itemCount: notes.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data = notes[index].data() as Map<String, dynamic>;
                      final text = data['text'] ?? '';
                      final userName = data['userName'] ?? 'Unknown';
                      final timestamp =
                          (data['timestamp'] as Timestamp?)?.toDate();
                      final timeString =
                          timestamp != null
                              ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} '
                                  '${timestamp.day}/${timestamp.month}/${timestamp.year}'
                              : '';
                      final isCurrentUser =
                          userName ==
                          (_authController.currentUser?.displayName ?? '');
                      return Align(
                        alignment:
                            isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCurrentUser
                                    ? colorScheme.primary.withValues(alpha: 0.15)
                                    : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(
                                isCurrentUser ? 18 : 4,
                              ),
                              bottomRight: Radius.circular(
                                isCurrentUser ? 4 : 18,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    userName,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (isCurrentUser)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      isCurrentUser
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeString,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.outline.withValues(alpha: 0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _noteController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Add a note...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _sending ? null : _sendNote,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child:
                              _sending
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                  : Icon(
                                    Icons.send_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 24,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
