import 'package:cached_network_image/cached_network_image.dart';
import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/post/components/expandable_description.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentItem extends ConsumerStatefulWidget {
  final CommentModel comment;
  final ContentPostV3Response content;
  final Function(String)? onReply;

  const CommentItem({
    super.key,
    required this.comment,
    required this.content,
    this.onReply,
  });

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  bool _isEditing = false;
  late TextEditingController _editController;
  late String _commentText;
  bool _showReplyBox = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likeCount = 0;
  int _dislikeCount = 0;
  final _replyController = TextEditingController();
  final _focusNode = FocusNode();
  int _currentLength = 0;

  void _updateCharCount() {
    setState(() {
      _currentLength = _replyController.text.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _commentText = widget.comment.text;
    _editController = TextEditingController(text: _commentText);
    _likeCount = widget.comment.likes;
    _replyController.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    _editController.dispose();
    _replyController.removeListener(_updateCharCount);
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleEditSubmit() async {
    if (_editController.text.trim().length >= 3 &&
        _editController.text.trim().length <= 1500) {
      try {
        final editedComment = await fpApiRequests.editComment(
            widget.comment.id, _editController.text.trim());

        if (editedComment == 'OK') {
          if (mounted) {
            setState(() {
              _commentText = _editController.text.trim();
              _isEditing = false;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to edit comment')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit comment: $e')),
          );
        }
      }
    }
  }

  void _toggleReplyBox() {
    setState(() {
      _showReplyBox = !_showReplyBox;
      if (_showReplyBox) {
        _replyController.text = '@${widget.comment.user.username} ';
        Future.delayed(Duration.zero, () => _focusNode.requestFocus());
      }
    });
  }

  void _handleReply() {
    if (_replyController.text.length >= 3 &&
        _replyController.text.length <= 1500) {
      if (widget.onReply != null) {
        widget.onReply!(_replyController.text);
      }
      setState(() {
        _showReplyBox = false;
      });
      _replyController.clear();
    }
  }

  String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 6) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    int hour = dateTime.hour % 12;
    hour = hour == 0 ? 12 : hour;

    return '${months[dateTime.month - 1]} ${dateTime.day.toString().padLeft(2, '0')}, ${dateTime.year} '
        '$hour:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    widget.comment.user.id != widget.content.creator?.owner
                        ? widget.comment.user.profileImage.path != null &&
                                (widget.comment.user.profileImage.path ?? '')
                                    .isNotEmpty
                            ? CachedNetworkImageProvider(
                                widget.comment.user.profileImage.path ?? '')
                            : AssetImage('assets/placeholder.png')
                        : widget.content.channel?.icon?.path != null &&
                                (widget.content.channel?.icon?.path ?? '')
                                    .isNotEmpty
                            ? CachedNetworkImageProvider(
                                widget.content.channel?.icon?.path ?? '')
                            : AssetImage('assets/placeholder.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.comment.user.id !=
                            widget.content.creator?.owner)
                          Text(
                            widget.comment.user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          Text(
                            widget.content.channel?.title ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          Tooltip(
                            message: 'Creator',
                            child: const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          const SizedBox(width: 8),
                        Tooltip(
                          message:
                              'Posted on ${formatDateTime(widget.comment.postDate)}',
                          child: Text(
                            getRelativeTime(widget.comment.postDate),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                        ),
                        if (widget.comment.isEdited) const SizedBox(width: 8),
                        if (widget.comment.isEdited)
                          Tooltip(
                            message: widget.comment.editDate != null
                                ? 'Comment was edited ${widget.comment.editCount} times. Last edited on ${formatDateTime(widget.comment.editDate!)}'
                                : 'Comment was edited ${widget.comment.editCount} times',
                            child: Text(
                              '<edited>',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ),
                        if (widget.comment.pinDate != null)
                          const SizedBox(width: 8),
                        if (widget.comment.pinDate != null)
                          Tooltip(
                            message:
                                'Pinned on ${formatDateTime(widget.comment.pinDate!)}',
                            child: Icon(
                              Icons.push_pin,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                          ),
                        Spacer(),
                        if (widget.comment.user.id ==
                            rootLayoutKey.currentState?.user?.id)
                          MenuAnchor(
                            style: MenuStyle(
                              padding:
                                  WidgetStatePropertyAll(EdgeInsets.all(5)),
                              minimumSize: WidgetStatePropertyAll(Size.zero),
                            ),
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                    _editController.text = _commentText;
                                  });
                                },
                                child: const Text('Edit'),
                              ),
                              MenuItemButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return AlertDialog(
                                        title: const Text('Delete Comment'),
                                        content: const Text(
                                            'Are you sure you want to delete this comment?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(dialogContext)
                                                    .pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              var res = await fpApiRequests
                                                  .deleteComment(
                                                      widget.comment.id);

                                              if (res == 'OK') {
                                                if (mounted) {
                                                  setState(() {
                                                    _commentText =
                                                        'This comment has been deleted.';
                                                  });
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Failed to delete comment'),
                                                    ),
                                                  );
                                                }
                                              }

                                              if (context.mounted) {
                                                Navigator.of(dialogContext)
                                                    .pop();
                                              }
                                            },
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                            builder: (BuildContext context,
                                MenuController controller, Widget? child) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.more_vert, size: 17.0),
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                              );
                            },
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    _isEditing
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _editController,
                                maxLength: 1500,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  hintText: 'Edit your comment',
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey[800]!),
                                  ),
                                  counterText: '',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_editController.text.length}/1500',
                                      style: TextStyle(
                                        color:
                                            _editController.text.length > 1500
                                                ? Colors.red
                                                : Colors.grey[400],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      child: const Text('CANCEL'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed:
                                          _editController.text.trim().length >=
                                                      3 &&
                                                  _editController.text
                                                          .trim()
                                                          .length <=
                                                      1500
                                              ? _handleEditSubmit
                                              : null,
                                      child: const Text('SAVE'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ExpandableDescription(
                            description: _commentText,
                            initialLines: 6,
                          ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                          ),
                          icon: AnimatedTheme(
                            data: Theme.of(context).copyWith(
                              iconTheme: IconThemeData(
                                size: 16,
                                color: _isLiked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.thumb_up_outlined),
                          ),
                          label: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isLiked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('$_likeCount'),
                          ),
                          onPressed: () async {
                            final res = await fpApiRequests.likeComment(
                                widget.comment.id, widget.content.id!);
                            if (res == 'success') {
                              setState(() {
                                if (_isLiked) {
                                  _likeCount--;
                                  _isLiked = false;
                                } else {
                                  _likeCount++;
                                  if (_isDisliked) {
                                    _dislikeCount--;
                                    _isDisliked = false;
                                  }
                                  _isLiked = true;
                                }
                              });
                            } else if (res == 'removed') {
                              setState(() {
                                _likeCount--;
                                _isLiked = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 5),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                          ),
                          icon: AnimatedTheme(
                            data: Theme.of(context).copyWith(
                              iconTheme: IconThemeData(
                                size: 16,
                                color: _isDisliked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.thumb_down_outlined),
                          ),
                          label: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDisliked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('$_dislikeCount'),
                          ),
                          onPressed: () async {
                            final res = await fpApiRequests.dislikeComment(
                                widget.comment.id, widget.content.id!);
                            if (res == 'success') {
                              setState(() {
                                if (_isDisliked) {
                                  _dislikeCount--;
                                  _isDisliked = false;
                                } else {
                                  _dislikeCount++;
                                  if (_isLiked) {
                                    _likeCount--;
                                    _isLiked = false;
                                  }
                                  _isDisliked = true;
                                }
                              });
                            } else if (res == 'removed') {
                              setState(() {
                                _dislikeCount--;
                                _isDisliked = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _toggleReplyBox,
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                          ),
                          child: Text(
                            'REPLY',
                            style: TextStyle(
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
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _replyController,
                    focusNode: _focusNode,
                    maxLength: 1500,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a reply',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _handleReply(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '$_currentLength/1500',
                          style: TextStyle(
                            color: _currentLength > 1500
                                ? Colors.red
                                : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showReplyBox = false),
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed:
                              _currentLength >= 3 && _currentLength <= 1500
                                  ? _handleReply
                                  : null,
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                          ),
                          child: Text(
                            'REPLY',
                            style: TextStyle(
                              color:
                                  _currentLength >= 3 && _currentLength <= 1500
                                      ? Colors.white
                                      : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showReplyBox
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    ));
  }
}
