import 'dart:math';

import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/post/components/comment_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentHolder extends ConsumerStatefulWidget {
  final CommentModel comment;
  final ContentPostV3Response content;

  const CommentHolder({
    super.key,
    required this.comment,
    required this.content,
  });

  @override
  ConsumerState<CommentHolder> createState() => _CommentHolderState();
}

class _CommentHolderState extends ConsumerState<CommentHolder> {
  late List<CommentModel> _replies;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _replies = widget.comment.replies ?? [];
  }

  Future<void> _loadMoreReplies() async {
    setState(() {
      _isLoadingMore = true;
    });

    await fpApiRequests
        .getReplies(
      widget.comment.id,
      widget.content.id!,
      5,
      _replies.last.id,
    )
        .then((replies) {
      setState(() {
        _replies.addAll(replies);
        _isLoadingMore = false;
      });
    });
  }

  Future<CommentModel> sendreply(
      String blogPost, String replyTo, String text) async {
    final reply = await fpApiRequests.comment(blogPost, text, replyto: replyTo);

    setState(() {
      _replies.insert(
          0,
          CommentModel(
            id: reply!.id,
            blogPost: reply.blogPost,
            user: reply.user,
            text: reply.text,
            replying: reply.replying,
            postDate: reply.postDate,
            editDate: reply.editDate,
            pinDate: reply.pinDate,
            editCount: reply.editCount,
            isEdited: reply.isEdited,
            likes: reply.likes,
            dislikes: reply.dislikes,
            score: reply.score,
            interactionCounts: reply.interactionCounts,
            totalReplies: reply.totalReplies,
            replies: reply.replies,
            userInteraction: reply.userInteraction,
          ));
    });
    return reply!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentItem(
          comment: widget.comment,
          content: widget.content,
          onReply: (text) {
            sendreply(widget.content.id!, widget.comment.id, text);
          },
        ),
        if (_replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._replies.map((reply) => CommentItem(
                      key: ValueKey(reply.id),
                      comment: reply,
                      content: widget.content,
                      onReply: (text) {
                        sendreply(widget.content.id!, widget.comment.id, text);
                      },
                    )),
                if ((widget.comment.totalReplies ?? 0) > _replies.length)
                  TextButton(
                    onPressed: _isLoadingMore ? null : _loadMoreReplies,
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            'Show ${min(5, (widget.comment.totalReplies ?? 0) - _replies.length)} more ${((widget.comment.totalReplies ?? 0) - _replies.length) == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
