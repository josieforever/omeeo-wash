import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omeeowash/models/booking_model.dart';
import 'package:video_player/video_player.dart';

import '../../../../widgets.dart/colors.dart';

enum ChatMessageType { text, image, video, system }

enum ChatActorRole { customer, laundry, rider }

enum RiderLegRole { pickupRider, deliveryRider }

class BookingChatScreen extends StatefulWidget {
  final BookingModel booking;
  final String currentUserRole;
  final String otherParticipantRole;
  final String? otherParticipantId;

  const BookingChatScreen({
    super.key,
    required this.booking,
    required this.currentUserRole,
    required this.otherParticipantRole,
    this.otherParticipantId,
  });

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  static const double _maxImageSizeMb = 10;
  static const double _maxVideoSizeMb = 50;
  static const int _maxVideoDurationSeconds = 30;

  late final ChatContext _chatContext;
  late final ChatService _chatService;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? _pickedImageFile;
  File? _pickedVideoFile;

  bool _isSending = false;
  bool _isPickingMedia = false;
  bool _didInitialScroll = false;
  bool _isNearBottom = true;
  bool _isSelectionMode = false;
  bool _isDeletingMessages = false;

  String? _lastBottomMessageId;
  StreamSubscription<List<ChatMessage>>? _messageSub;

  final Set<String> _selectedMessageIds = <String>{};

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  String get _bookingId => widget.booking.id;

  bool get _canSend {
    return !_isSending &&
        (_messageController.text.trim().isNotEmpty ||
            _pickedImageFile != null ||
            _pickedVideoFile != null);
  }

  @override
  void initState() {
    super.initState();

    _chatContext = ChatContextResolver.resolve(
      booking: widget.booking,
      currentUserId: _currentUserId,
      currentUserRole: widget.currentUserRole,
      otherParticipantRole: widget.otherParticipantRole,
      otherParticipantId: widget.otherParticipantId,
    );

    _chatService = ChatService(chatContext: _chatContext);

    _messageController.addListener(_handleComposerChanged);

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final distanceFromBottom =
          _scrollController.position.maxScrollExtent -
          _scrollController.position.pixels;
      _isNearBottom = distanceFromBottom < 120;
    });

    _messageSub = _chatService.streamMessages().listen((messages) {
      if (!mounted) return;

      if (!_didInitialScroll && messages.isNotEmpty) {
        _didInitialScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(jump: true);
        });
      }

      if (messages.isNotEmpty) {
        final currentBottomId = messages.last.id;
        final bottomChanged = currentBottomId != _lastBottomMessageId;
        _lastBottomMessageId = currentBottomId;

        if (bottomChanged && _isNearBottom && !_isSelectionMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }

      _markIncomingMessagesAsRead(messages);

      if (_isSelectionMode) {
        final liveIds = messages.map((e) => e.id).toSet();
        _selectedMessageIds.removeWhere((id) => !liveIds.contains(id));
        if (_selectedMessageIds.isEmpty) {
          _exitSelectionMode();
        } else {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _messageController.removeListener(_handleComposerChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    if (mounted) setState(() {});
  }

  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }

      if (_selectedMessageIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    if (!mounted) return;
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  Future<void> _scrollToBottom({bool jump = false}) async {
    if (!_scrollController.hasClients) return;

    if (jump) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      return;
    }

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _markIncomingMessagesAsRead(List<ChatMessage> messages) async {
    final unreadIncoming = messages
        .where((m) => m.senderId != _currentUserId && !m.isRead)
        .map((m) => m.id)
        .toList();

    if (unreadIncoming.isEmpty) return;

    try {
      await _chatService.markMessagesAsRead(messageIds: unreadIncoming);
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    if (_isPickingMedia || _isSelectionMode) return;

    setState(() {
      _isPickingMedia = true;
      _pickedVideoFile = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      final sizeInMb = await file.length() / (1024 * 1024);

      if (sizeInMb > _maxImageSizeMb) {
        _showSnack(
          'Image is too large. Maximum allowed size is ${_maxImageSizeMb.toInt()} MB.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _pickedImageFile = file;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingMedia = false;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingMedia || _isSelectionMode) return;

    setState(() {
      _isPickingMedia = true;
      _pickedImageFile = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      final sizeInMb = await file.length() / (1024 * 1024);

      if (sizeInMb > _maxVideoSizeMb) {
        _showSnack(
          'Video is too large. Maximum allowed size is ${_maxVideoSizeMb.toInt()} MB.',
        );
        return;
      }

      final durationInSeconds = await _chatService.getVideoDurationInSeconds(
        file,
      );

      if (durationInSeconds == null) {
        _showSnack('Could not read video duration.');
        return;
      }

      if (durationInSeconds > _maxVideoDurationSeconds) {
        _showSnack(
          'Video must not be longer than $_maxVideoDurationSeconds seconds.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _pickedVideoFile = file;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingMedia = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (!_canSend) return;

    if (_chatContext.senderId.isEmpty || _chatContext.receiverId.isEmpty) {
      _showSnack('Chat participants are not available for this booking yet.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      ChatMessageType messageType = ChatMessageType.text;
      String? mediaUrl;
      String? storagePath;
      String? fileName;
      String? mimeType;
      int? fileSizeBytes;
      int? videoDurationSeconds;

      if (_pickedImageFile != null) {
        messageType = ChatMessageType.image;
        final upload = await _chatService.uploadChatMedia(
          file: _pickedImageFile!,
          folder: 'images',
        );
        mediaUrl = upload.url;
        storagePath = upload.storagePath;
        fileName = upload.fileName;
        mimeType = upload.mimeType;
        fileSizeBytes = upload.fileSizeBytes;
      }

      if (_pickedVideoFile != null) {
        messageType = ChatMessageType.video;
        videoDurationSeconds = await _chatService.getVideoDurationInSeconds(
          _pickedVideoFile!,
        );

        if (videoDurationSeconds == null) {
          throw Exception('Could not read video duration.');
        }

        if (videoDurationSeconds > _maxVideoDurationSeconds) {
          throw Exception(
            'Video must not be longer than $_maxVideoDurationSeconds seconds.',
          );
        }

        final upload = await _chatService.uploadChatMedia(
          file: _pickedVideoFile!,
          folder: 'videos',
        );
        mediaUrl = upload.url;
        storagePath = upload.storagePath;
        fileName = upload.fileName;
        mimeType = upload.mimeType;
        fileSizeBytes = upload.fileSizeBytes;
      }

      await _chatService.sendMessage(
        messageType: messageType,
        text: text,
        mediaUrl: mediaUrl,
        storagePath: storagePath,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        videoDurationSeconds: videoDurationSeconds,
      );

      _messageController.clear();

      if (mounted) {
        setState(() {
          _pickedImageFile = null;
          _pickedVideoFile = null;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty || _isDeletingMessages) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final count = _selectedMessageIds.length;
        return AlertDialog(
          title: Text(count == 1 ? 'Delete message?' : 'Delete messages?'),
          content: Text(
            count == 1
                ? 'This will remove the message for both sides.'
                : 'This will remove all selected messages for both sides.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeletingMessages = true;
    });

    try {
      await _chatService.deleteMessagesForEveryone(
        messageIds: _selectedMessageIds.toList(),
      );

      if (!mounted) return;
      _showSnack(
        _selectedMessageIds.length == 1
            ? 'Message deleted.'
            : 'Messages deleted.',
      );
      _exitSelectionMode();
    } catch (e) {
      _showSnack('Failed to delete messages.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingMessages = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        leadingWidth: 56,
        leading: IconButton(
          onPressed: _exitSelectionMode,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          '${_selectedMessageIds.length} selected',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isDeletingMessages ? null : _deleteSelectedMessages,
            icon: _isDeletingMessages
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            onPressed: _exitSelectionMode,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.black87,
      centerTitle: false,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Container(
                color: const Color(0xFFE36C9A),
                child: Icon(
                  _chatContext.avatarIcon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _chatContext.title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.streamMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Failed to load chat.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return EmptyChatView(
                          collectionName: _chatContext.collectionName,
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          10,
                          14,
                          10,
                          _isSelectionMode ? 20 : 110,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final previous = index > 0
                              ? messages[index - 1]
                              : null;
                          final isMine = message.senderId == _currentUserId;

                          final showDaySeparator =
                              previous == null ||
                              !_isSameDay(
                                previous.createdAt ?? DateTime.now(),
                                message.createdAt ?? DateTime.now(),
                              );

                          final isFirstSequence =
                              previous == null ||
                              previous.senderId != message.senderId ||
                              !_isSameDay(
                                previous.createdAt ?? DateTime.now(),
                                message.createdAt ?? DateTime.now(),
                              );

                          final isSelected = _selectedMessageIds.contains(
                            message.id,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDaySeparator)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 18,
                                    bottom: 14,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatDaySeparator(
                                        message.createdAt ?? DateTime.now(),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              _MessageBubble(
                                message: message,
                                isMine: isMine,
                                isFirstSequence: isFirstSequence,
                                senderLabel: message.senderName,
                                showSenderLabel: !isMine && isFirstSequence,
                                timestamp: _formatTimestamp(
                                  message.createdAt ?? DateTime.now(),
                                ),
                                isSelectionMode: _isSelectionMode,
                                isSelected: isSelected,
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enterSelectionMode(message.id);
                                  }
                                },
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleMessageSelection(message.id);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_pickedImageFile != null || _pickedVideoFile != null)
            Positioned.fill(
              child: _ComposerMediaPreview(
                pickedImageFile: _pickedImageFile,
                pickedVideoFile: _pickedVideoFile,
                onRemoveImage: () {
                  setState(() {
                    _pickedImageFile = null;
                  });
                },
                onRemoveVideo: () {
                  setState(() {
                    _pickedVideoFile = null;
                  });
                },
              ),
            ),
          if (!_isSelectionMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MessageInputBar(
                controller: _messageController,
                onPickImage: _pickImage,
                onPickVideo: _pickVideo,
                onSend: _sendMessage,
                isSending: _isSending,
                canSend: _canSend,
                isOverlayMode:
                    _pickedImageFile != null || _pickedVideoFile != null,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    final normalized = DateTime(date.year, date.month, date.day);
    return normalized == yesterday;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(now, date);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 7));
    final normalized = DateTime(date.year, date.month, date.day);

    return !normalized.isBefore(start) && normalized.isBefore(end);
  }

  String _formatDaySeparator(DateTime date) {
    if (_isToday(date)) return 'Today';
    if (_isYesterday(date)) return 'Yesterday';
    if (_isInCurrentWeek(date)) return DateFormat('EEEE').format(date);
    return DateFormat('MMMM d, y').format(date);
  }
}

class ChatContext {
  final String bookingId;
  final String collectionName;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String receiverId;
  final String receiverRole;
  final String title;
  final IconData avatarIcon;

  const ChatContext({
    required this.bookingId,
    required this.collectionName,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.receiverId,
    required this.receiverRole,
    required this.title,
    required this.avatarIcon,
  });
}

class ChatContextResolver {
  static ChatContext resolve({
    required BookingModel booking,
    required String currentUserId,
    required String currentUserRole,
    required String otherParticipantRole,
    String? otherParticipantId,
  }) {
    final currentRole = _parseRole(currentUserRole);
    final otherRole = _parseRole(otherParticipantRole);

    final currentLeg = _resolveRiderLeg(
      booking: booking,
      userId: currentUserId,
      role: currentRole,
    );

    final otherLeg = _resolveRiderLeg(
      booking: booking,
      userId: otherParticipantId,
      role: otherRole,
    );

    String collectionName;
    String senderRole;
    String receiverRole;

    if (currentRole == ChatActorRole.customer &&
        otherRole == ChatActorRole.rider) {
      if (otherLeg != RiderLegRole.pickupRider) {
        throw Exception(
          'Customer can only chat with the pickup rider or delivery rider through the matching subcollection.',
        );
      }
      collectionName = 'customer_pickupRider';
      senderRole = 'customer';
      receiverRole = 'pickupRider';
    } else if (currentRole == ChatActorRole.rider &&
        otherRole == ChatActorRole.customer) {
      if (currentLeg == RiderLegRole.pickupRider) {
        collectionName = 'customer_pickupRider';
        senderRole = 'pickupRider';
        receiverRole = 'customer';
      } else if (currentLeg == RiderLegRole.deliveryRider) {
        collectionName = 'deliveryRider_customer';
        senderRole = 'deliveryRider';
        receiverRole = 'customer';
      } else {
        throw Exception('This rider is not assigned to the booking.');
      }
    } else if (currentRole == ChatActorRole.rider &&
        otherRole == ChatActorRole.laundry) {
      if (currentLeg == RiderLegRole.pickupRider) {
        collectionName = 'pickupRider_laundry';
        senderRole = 'pickupRider';
        receiverRole = 'laundry';
      } else if (currentLeg == RiderLegRole.deliveryRider) {
        collectionName = 'laundry_deliveryRider';
        senderRole = 'deliveryRider';
        receiverRole = 'laundry';
      } else {
        throw Exception('This rider is not assigned to the booking.');
      }
    } else if (currentRole == ChatActorRole.laundry &&
        otherRole == ChatActorRole.rider) {
      if (otherLeg == RiderLegRole.pickupRider) {
        collectionName = 'pickupRider_laundry';
        senderRole = 'laundry';
        receiverRole = 'pickupRider';
      } else if (otherLeg == RiderLegRole.deliveryRider) {
        collectionName = 'laundry_deliveryRider';
        senderRole = 'laundry';
        receiverRole = 'deliveryRider';
      } else {
        throw Exception('The selected rider is not assigned to the booking.');
      }
    } else if (currentRole == ChatActorRole.customer &&
        otherRole == ChatActorRole.laundry) {
      collectionName = 'customer_laundry';
      senderRole = 'customer';
      receiverRole = 'laundry';
    } else if (currentRole == ChatActorRole.laundry &&
        otherRole == ChatActorRole.customer) {
      collectionName = 'customer_laundry';
      senderRole = 'laundry';
      receiverRole = 'customer';
    } else {
      throw Exception(
        'Unsupported chat pairing: $currentUserRole -> $otherParticipantRole',
      );
    }

    final senderId = _resolveParticipantId(
      booking: booking,
      role: senderRole,
      currentUserId: currentUserId,
    );

    final receiverId = _resolveParticipantId(
      booking: booking,
      role: receiverRole,
      currentUserId: otherParticipantId ?? '',
    );

    final senderName = _resolveDisplayName(
      booking: booking,
      role: senderRole,
      fallbackUserId: currentUserId,
    );

    final title = _resolveTitle(booking: booking, role: receiverRole);

    final avatarIcon = _resolveAvatarIcon(receiverRole);

    return ChatContext(
      bookingId: booking.id,
      collectionName: collectionName,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      receiverId: receiverId,
      receiverRole: receiverRole,
      title: title,
      avatarIcon: avatarIcon,
    );
  }

  static ChatActorRole _parseRole(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'customer':
        return ChatActorRole.customer;
      case 'laundry':
        return ChatActorRole.laundry;
      case 'rider':
        return ChatActorRole.rider;
      default:
        throw Exception('Invalid chat role: $raw');
    }
  }

  static RiderLegRole? _resolveRiderLeg({
    required BookingModel booking,
    required ChatActorRole role,
    required String? userId,
  }) {
    if (role != ChatActorRole.rider ||
        userId == null ||
        userId.trim().isEmpty) {
      return null;
    }

    if (booking.pickupRiderId == userId) return RiderLegRole.pickupRider;
    if (booking.deliveryRiderId == userId) return RiderLegRole.deliveryRider;
    return null;
  }

  static String _resolveParticipantId({
    required BookingModel booking,
    required String role,
    required String currentUserId,
  }) {
    switch (role) {
      case 'customer':
        return booking.customerId;
      case 'laundry':
        return booking.laundryId ?? '';
      case 'pickupRider':
        return booking.pickupRiderId ?? currentUserId;
      case 'deliveryRider':
        return booking.deliveryRiderId ?? currentUserId;
      default:
        return '';
    }
  }

  static String _resolveDisplayName({
    required BookingModel booking,
    required String role,
    required String fallbackUserId,
  }) {
    switch (role) {
      case 'customer':
        return booking.customerName.trim().isEmpty
            ? 'Customer'
            : booking.customerName;
      case 'laundry':
        final name = booking.laundryName ?? '';
        return name.trim().isEmpty ? 'Laundry' : name;
      case 'pickupRider':
        final name = booking.pickupRiderName ?? '';
        return name.trim().isEmpty ? 'Pickup Rider' : name;
      case 'deliveryRider':
        final name = booking.deliveryRiderName ?? '';
        return name.trim().isEmpty ? 'Delivery Rider' : name;
      default:
        return fallbackUserId;
    }
  }

  static String _resolveTitle({
    required BookingModel booking,
    required String role,
  }) {
    switch (role) {
      case 'customer':
        return booking.customerName.trim().isEmpty
            ? 'Customer'
            : booking.customerName;
      case 'laundry':
        final name = booking.laundryName ?? '';
        return name.trim().isEmpty ? 'Laundry' : name;
      case 'pickupRider':
        final name = booking.pickupRiderName ?? '';
        return name.trim().isEmpty ? 'Pickup Rider' : name;
      case 'deliveryRider':
        final name = booking.deliveryRiderName ?? '';
        return name.trim().isEmpty ? 'Delivery Rider' : name;
      default:
        return 'Chat';
    }
  }

  static IconData _resolveAvatarIcon(String role) {
    switch (role) {
      case 'customer':
        return Icons.person_rounded;
      case 'laundry':
        return Icons.local_laundry_service_rounded;
      case 'pickupRider':
      case 'deliveryRider':
        return Icons.delivery_dining_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

class ChatService {
  ChatService({
    required ChatContext chatContext,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _chatContext = chatContext,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final ChatContext _chatContext;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _chatCollection() {
    return _firestore
        .collection('bookings')
        .doc(_chatContext.bookingId)
        .collection(_chatContext.collectionName);
  }

  DocumentReference<Map<String, dynamic>> _bookingRef() {
    return _firestore.collection('bookings').doc(_chatContext.bookingId);
  }

  Stream<List<ChatMessage>> streamMessages() {
    return _chatCollection()
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<int?> getVideoDurationInSeconds(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration.inSeconds;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<_UploadedChatMedia> uploadChatMedia({
    required File file,
    required String folder,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

    final storagePath =
        'booking_chats/${_chatContext.bookingId}/${_chatContext.collectionName}/$folder/$fileName';

    final ref = _storage.ref().child(storagePath);
    final task = await ref.putFile(file);
    final url = await task.ref.getDownloadURL();

    return _UploadedChatMedia(
      url: url,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: _guessMimeType(file.path),
      fileSizeBytes: await file.length(),
    );
  }

  Future<void> sendMessage({
    required ChatMessageType messageType,
    required String text,
    String? mediaUrl,
    String? storagePath,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    int? videoDurationSeconds,
  }) async {
    final bookingRef = _bookingRef();
    final messageRef = _chatCollection().doc();

    final String normalizedText = text.trim();
    final String previewText = _messagePreview(
      type: messageType,
      text: normalizedText,
    );

    final batch = _firestore.batch();

    batch.set(messageRef, {
      'bookingId': _chatContext.bookingId,
      'chatCollection': _chatContext.collectionName,
      'senderId': _chatContext.senderId,
      'senderRole': _chatContext.senderRole,
      'senderName': _chatContext.senderName,
      'receiverId': _chatContext.receiverId,
      'receiverRole': _chatContext.receiverRole,
      'messageType': describeEnum(messageType),
      'text': normalizedText,
      'mediaUrl': mediaUrl,
      'storagePath': storagePath,
      'mediaThumbnailUrl': null,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      'videoDurationSeconds': videoDurationSeconds,
      'isRead': false,
      'readAt': null,
      'isEdited': false,
      'editedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(bookingRef, {
      'chatMeta.${_chatContext.collectionName}.lastMessage': previewText,
      'chatMeta.${_chatContext.collectionName}.lastMessageType': describeEnum(
        messageType,
      ),
      'chatMeta.${_chatContext.collectionName}.lastMessageSenderId':
          _chatContext.senderId,
      'chatMeta.${_chatContext.collectionName}.lastMessageSenderRole':
          _chatContext.senderRole,
      'chatMeta.${_chatContext.collectionName}.lastMessageAt':
          FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> markMessagesAsRead({required List<String> messageIds}) async {
    if (messageIds.isEmpty) return;

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final id in messageIds) {
      batch.update(_chatCollection().doc(id), {
        'isRead': true,
        'readAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  Future<void> deleteMessagesForEveryone({
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    final docs = await Future.wait(
      messageIds.map((id) => _chatCollection().doc(id).get()),
    );

    for (final snap in docs) {
      if (!snap.exists) continue;

      final data = snap.data();
      final storagePath = data?['storagePath']?.toString();

      if (storagePath != null && storagePath.trim().isNotEmpty) {
        try {
          await _storage.ref().child(storagePath).delete();
        } catch (_) {}
      }
    }

    final batch = _firestore.batch();
    for (final id in messageIds) {
      batch.delete(_chatCollection().doc(id));
    }
    await batch.commit();

    await _refreshBookingChatMeta();
  }

  Future<void> _refreshBookingChatMeta() async {
    final query = await _chatCollection()
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      await _bookingRef().set({
        'chatMeta.${_chatContext.collectionName}.lastMessage': null,
        'chatMeta.${_chatContext.collectionName}.lastMessageType': null,
        'chatMeta.${_chatContext.collectionName}.lastMessageSenderId': null,
        'chatMeta.${_chatContext.collectionName}.lastMessageSenderRole': null,
        'chatMeta.${_chatContext.collectionName}.lastMessageAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final last = query.docs.first.data();

    await _bookingRef().set({
      'chatMeta.${_chatContext.collectionName}.lastMessage': _messagePreview(
        type: ChatMessage._parseMessageType(last['messageType']),
        text: (last['text'] ?? '').toString(),
      ),
      'chatMeta.${_chatContext.collectionName}.lastMessageType':
          last['messageType'],
      'chatMeta.${_chatContext.collectionName}.lastMessageSenderId':
          last['senderId'],
      'chatMeta.${_chatContext.collectionName}.lastMessageSenderRole':
          last['senderRole'],
      'chatMeta.${_chatContext.collectionName}.lastMessageAt':
          last['createdAt'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _messagePreview({
    required ChatMessageType type,
    required String text,
  }) {
    if (type == ChatMessageType.text) {
      return text.isEmpty ? 'Message' : text;
    }
    if (type == ChatMessageType.image) {
      return '📷 Sent an image';
    }
    if (type == ChatMessageType.video) {
      return '🎥 Sent a video';
    }
    return text.isEmpty ? 'System update' : text;
  }

  String? _guessMimeType(String path) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lower.endsWith('.mkv')) {
      return 'video/x-matroska';
    }

    return null;
  }
}

class ChatMessage {
  final String id;
  final String bookingId;
  final String chatCollection;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String receiverId;
  final String receiverRole;
  final ChatMessageType messageType;
  final String text;
  final String? mediaUrl;
  final String? storagePath;
  final String? mediaThumbnailUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final int? videoDurationSeconds;
  final bool isRead;
  final DateTime? readAt;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.chatCollection,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.receiverId,
    required this.receiverRole,
    required this.messageType,
    required this.text,
    required this.mediaUrl,
    required this.storagePath,
    required this.mediaThumbnailUrl,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.videoDurationSeconds,
    required this.isRead,
    required this.readAt,
    required this.isEdited,
    required this.editedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      bookingId: (map['bookingId'] ?? '').toString(),
      chatCollection: (map['chatCollection'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      senderRole: (map['senderRole'] ?? '').toString(),
      senderName: (map['senderName'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      receiverRole: (map['receiverRole'] ?? '').toString(),
      messageType: _parseMessageType(map['messageType']),
      text: (map['text'] ?? '').toString(),
      mediaUrl: _nullableString(map['mediaUrl']),
      storagePath: _nullableString(map['storagePath']),
      mediaThumbnailUrl: _nullableString(map['mediaThumbnailUrl']),
      fileName: _nullableString(map['fileName']),
      mimeType: _nullableString(map['mimeType']),
      fileSizeBytes: _nullableInt(map['fileSizeBytes']),
      videoDurationSeconds: _nullableInt(map['videoDurationSeconds']),
      isRead: map['isRead'] == true,
      readAt: _parseDateTime(map['readAt']),
      isEdited: map['isEdited'] == true,
      editedAt: _parseDateTime(map['editedAt']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static ChatMessageType _parseMessageType(dynamic value) {
    final raw = (value ?? 'text').toString().trim().toLowerCase();
    switch (raw) {
      case 'image':
        return ChatMessageType.image;
      case 'video':
        return ChatMessageType.video;
      case 'system':
        return ChatMessageType.system;
      case 'text':
      default:
        return ChatMessageType.text;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

class _UploadedChatMedia {
  final String url;
  final String storagePath;
  final String fileName;
  final String? mimeType;
  final int fileSizeBytes;

  const _UploadedChatMedia({
    required this.url,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
  });
}

class EmptyChatView extends StatelessWidget {
  final String collectionName;

  const EmptyChatView({super.key, required this.collectionName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 58,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 14),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messages for $collectionName will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final Future<void> Function() onSend;
  final bool isSending;
  final bool canSend;
  final bool isOverlayMode;

  const _MessageInputBar({
    required this.controller,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onSend,
    required this.isSending,
    required this.canSend,
    required this.isOverlayMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isOverlayMode ? Colors.transparent : const Color(0xFFF2F2F2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  boxShadow: isOverlayMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'image') {
                          onPickImage();
                        } else if (value == 'video') {
                          onPickVideo();
                        }
                      },
                      color: Colors.white,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'image',
                          child: Text('Pick image'),
                        ),
                        PopupMenuItem(
                          value: 'video',
                          child: Text('Pick video'),
                        ),
                      ],
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.15,
                            child: const Icon(
                              Icons.attach_file_rounded,
                              color: Color(0xFF8F8F8F),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(
                              color: Color(0xFF9B9B9B),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              right: 8,
                              left: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canSend ? onSend : null,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: canSend
                      ? const Color(0xFFE8F7FC)
                      : const Color(0xFFE6E6E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 26,
                          color: canSend
                              ? const Color(0xFFE36C9A)
                              : const Color(0xFFB8B8B8),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerMediaPreview extends StatelessWidget {
  final File? pickedImageFile;
  final File? pickedVideoFile;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveVideo;

  const _ComposerMediaPreview({
    required this.pickedImageFile,
    required this.pickedVideoFile,
    required this.onRemoveImage,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          Positioned.fill(
            child: pickedImageFile != null
                ? GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _FullScreenImageViewer(
                            imagePath: pickedImageFile!.path,
                          ),
                        ),
                      );
                    },
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.file(
                          pickedImageFile!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : pickedVideoFile != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _VideoPreview(
                          filePath: pickedVideoFile!.path,
                          forBubble: true,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: GestureDetector(
              onTap: pickedImageFile != null ? onRemoveImage : onRemoveVideo,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
                child: SizedBox(height: 130),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool isFirstSequence;
  final String timestamp;
  final bool showSenderLabel;
  final String senderLabel;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isFirstSequence,
    required this.timestamp,
    required this.showSenderLabel,
    required this.senderLabel,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFFDDF4FB)
        : const Color(0xFFE2E5EA);

    final textColor = const Color(0xFF202020);
    final timeColor = isMine
        ? const Color(0xFF2AAFC9)
        : const Color(0xFF9E9E9E);

    final margin = EdgeInsets.only(
      top: isFirstSequence ? 6 : 2,
      bottom: 2,
      left: isMine ? 72 : 12,
      right: isMine ? 12 : 72,
    );

    Widget buildContent() {
      switch (message.messageType) {
        case ChatMessageType.image:
          return GestureDetector(
            onTap: isSelectionMode
                ? onTap
                : () {
                    if (message.mediaUrl == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _FullScreenImageViewer(
                          imagePath: message.mediaUrl!,
                        ),
                      ),
                    );
                  },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: message.mediaUrl == null
                  ? const SizedBox.shrink()
                  : CachedNetworkImage(
                      imageUrl: message.mediaUrl!,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                    ),
            ),
          );

        case ChatMessageType.video:
          return SizedBox(
            width: 240,
            child: _VideoPreview(
              filePath: message.mediaUrl ?? '',
              forBubble: true,
            ),
          );

        case ChatMessageType.system:
        case ChatMessageType.text:
          return Text(
            message.text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.28,
            ),
          );
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: onLongPress,
      onTap: isSelectionMode ? onTap : null,
      child: Container(
        width: double.infinity,
        color: isSelected ? const Color(0x1AE36C9A) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Container(
          margin: margin,
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (showSenderLabel)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFE36C9A),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        senderLabel,
                        style: const TextStyle(
                          color: Color(0xFF8B8B8B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMine && isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 10),
                        child: _SelectionIndicator(isSelected: isSelected),
                      ),
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          message.messageType == ChatMessageType.text ||
                                  message.messageType == ChatMessageType.system
                              ? 16
                              : 8,
                          message.messageType == ChatMessageType.text ||
                                  message.messageType == ChatMessageType.system
                              ? 12
                              : 8,
                          message.messageType == ChatMessageType.text ||
                                  message.messageType == ChatMessageType.system
                              ? 16
                              : 8,
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMine ? 20 : 6),
                            bottomRight: Radius.circular(isMine ? 6 : 20),
                          ),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFFE36C9A),
                                  width: 1.4,
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: buildContent(),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timestamp,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: timeColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isRead
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 17,
                                    color: const Color(0xFF2AAFC9),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isMine && isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: _SelectionIndicator(isSelected: isSelected),
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
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;

  const _SelectionIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFFE36C9A) : Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFFE36C9A) : const Color(0xFFBEBEBE),
          width: 1.4,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String filePath;
  final bool forBubble;

  const _VideoPreview({required this.filePath, this.forBubble = false});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController(widget.filePath);
  }

  @override
  void didUpdateWidget(covariant _VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _disposeController();
      _initController(widget.filePath);
    }
  }

  Future<void> _initController(String path) async {
    try {
      final controller = path.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(path))
          : VideoPlayerController.file(File(path));

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (_) {}
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.forBubble
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Stack(
        children: [
          if (_isInitialized && _controller != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const CircularProgressIndicator(),
            ),
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _FullScreenVideoPlayer(filePath: widget.filePath),
                    ),
                  );
                },
                child: const Icon(
                  Icons.play_circle,
                  color: Colors.white70,
                  size: 52,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenVideoPlayer extends StatefulWidget {
  final String filePath;

  const _FullScreenVideoPlayer({required this.filePath});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _controller = widget.filePath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.filePath))
        : VideoPlayerController.file(File(widget.filePath));

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
      _startHideTimer();
    });

    _controller.addListener(() {
      if (!_isDragging && mounted) {
        setState(() {});
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) {
      return '${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}';
    }
    return '${twoDigits(m)}:${twoDigits(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
                if (_showControls) _startHideTimer();
              },
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (_showControls)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Slider(
                              value: _isDragging
                                  ? _dragPosition.inMilliseconds.toDouble()
                                  : _controller.value.position.inMilliseconds
                                        .toDouble(),
                              min: 0,
                              max: _controller.value.duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              onChangeStart: (_) {
                                setState(() => _isDragging = true);
                              },
                              onChanged: (value) {
                                setState(() {
                                  _dragPosition = Duration(
                                    milliseconds: value.toInt(),
                                  );
                                });
                              },
                              onChangeEnd: (value) async {
                                final position = Duration(
                                  milliseconds: value.toInt(),
                                );
                                await _controller.seekTo(position);
                                setState(() => _isDragging = false);
                                _startHideTimer();
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final current =
                                        await _controller.position ??
                                        Duration.zero;
                                    final target =
                                        current - const Duration(seconds: 10);
                                    await _controller.seekTo(
                                      target < Duration.zero
                                          ? Duration.zero
                                          : target,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_controller.value.isPlaying) {
                                        _controller.pause();
                                      } else {
                                        _controller.play();
                                      }
                                    });
                                    _startHideTimer();
                                  },
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final current =
                                        await _controller.position ??
                                        Duration.zero;
                                    await _controller.seekTo(
                                      current + const Duration(seconds: 10),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  if (_showControls)
                    Positioned(
                      top: 40,
                      left: 20,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imagePath.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: isNetwork
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.contain,
                      )
                    : Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
