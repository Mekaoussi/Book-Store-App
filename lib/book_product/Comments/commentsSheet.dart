import 'package:bookstore/book_product/Comments/comments_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Comment {
  final String id;
  final String username;
  final String text;
  final String userImageUrl;
  final String timeAgo;
  final int likes;
  final int? repliesCount;
  List<Comment> replies;
  bool is_open;
  final String? repliedToUsername;

  Comment({
    required this.id,
    required this.username,
    required this.text,
    required this.userImageUrl,
    required this.timeAgo,
    this.likes = 0,
    this.repliesCount,
    this.replies = const [],
    this.is_open = false,
    this.repliedToUsername,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      text: json['content'] ?? '',
      userImageUrl: json['profile_image'] ?? 'assets/images/me.jpg',
      timeAgo: _formatTimeAgo(json['created_at']),
      likes: 0,
      replies: [],
      repliesCount: json['replies_count'] ?? 0,
      repliedToUsername: json['replied_to_username'],
    );
  }

  static String _formatTimeAgo(String? dateString) {
    if (dateString == null) return '';

    try {
      final DateTime commentDate = DateTime.parse(dateString);
      final Duration difference = DateTime.now().difference(commentDate);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}

void showCommentsSheet(BuildContext context, String bookId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ChangeNotifierProvider(
      create: (_) => CommentsProvider(),
      child: CommentsSheet(bookId: bookId),
    ),
  );
}

class CommentsSheet extends StatefulWidget {
  final String bookId;

  const CommentsSheet({
    super.key,
    required this.bookId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;
  String? _replyingToId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSheetChanged);

    // Fetch comments when sheet is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommentsProvider>(context, listen: false)
          .fetchComments(widget.bookId);
    });
  }

  void _onSheetChanged() {
    if (_controller.size <= 0.3) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onSheetChanged);
    _controller.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _setReplyingTo(String commentId, String username) {
    setState(() {
      _replyingToId = commentId;
      _replyingToUsername = username;
    });

    // Focus on the text field and show keyboard
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.6,
      snap: true,
      snapSizes: const [0.6, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(),
              Expanded(
                child: Consumer<CommentsProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (provider.error != null) {
                      return Center(child: Text('Error: ${provider.error}'));
                    } else if (provider.comments.isEmpty) {
                      return const Center(child: Text('No comments yet'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: provider.comments.length,
                      itemBuilder: (context, index) {
                        return CommentWidget(
                          comment: provider.comments[index],
                          bookId: widget.bookId,
                          onReply: _setReplyingTo,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader() {
    return Column(
      children: [
        Container(
          width: 50,
          margin: const EdgeInsets.only(top: 10, bottom: 7),
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 7),
          child: Text(
            "Comments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 0.5,
            width: double.infinity,
            color: const Color.fromARGB(255, 60, 60, 60),
          ),
        )
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        left: 12,
        right: 12,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUsername != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    'Replying to ${_replyingToUsername}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToUsername != null
                        ? 'Reply to ${_replyingToUsername}...'
                        : 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.blue,
                      onPressed: () async {
                        if (_commentController.text.trim().isEmpty) return;

                        setState(() {
                          _isSubmitting = true;
                        });

                        // Hide keyboard when sending
                        FocusScope.of(context).unfocus();

                        final success = await Provider.of<CommentsProvider>(
                                context,
                                listen: false)
                            .addComment(
                          widget.bookId,
                          _commentController.text,
                          parentId: _replyingToId,
                          repliedToUsername: _replyingToUsername,
                        );

                        setState(() {
                          _isSubmitting = false;
                          if (success) {
                            _commentController.clear();
                            _replyingToId = null;
                            _replyingToUsername = null;
                          }
                        });
                      },
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final bool isReply;
  final String bookId;
  final String? parentId;
  final Function(String, String)? onReply;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.bookId,
    this.isReply = false,
    this.parentId,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isReply ? 36 : 12,
        8,
        12,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.userImageUrl.startsWith('http')
                ? NetworkImage(comment.userImageUrl) as ImageProvider
                : AssetImage(comment.userImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildCommentText(comment.text),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // Use the parent ID if this is already a reply
                        final targetId = isReply ? parentId! : comment.id;
                        onReply?.call(targetId, comment.username);
                      },
                      child: const Text(
                        'Reply',
                        style: TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                    ),
                    if (!isReply &&
                        (comment.repliesCount != null &&
                            comment.repliesCount! > 0)) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {
                          // Toggle showing replies
                          Provider.of<CommentsProvider>(context, listen: false)
                              .toggleCommentReplies(comment.id);
                        },
                        child: Text(
                          comment.is_open
                              ? "Hide replies"
                              : "View ${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply' : 'replies'}",
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (!isReply && comment.is_open) ...[
                  ...comment.replies.map((reply) => CommentWidget(
                        comment: reply,
                        isReply: true,
                        bookId: bookId,
                        parentId: comment.id,
                        onReply: onReply,
                      )),
                  if (comment.replies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 8),
                      child: InkWell(
                        onTap: () {
                          // Close replies
                          Provider.of<CommentsProvider>(context, listen: false)
                              .toggleCommentReplies(comment.id);
                        },
                        child: const Text(
                          "Hide replies",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // Handle like
                },
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              Text(
                comment.likes.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New method to handle the comment text with @mentions
  Widget _buildCommentText(String text) {
    // Check if the text starts with @username
    final RegExp mentionRegex = RegExp(r'^@(\w+)\s');
    final match = mentionRegex.firstMatch(text);

    if (match != null) {
      final username = match.group(1);
      final mentionEnd = match.end;
      final remainingText = text.substring(mentionEnd);

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '@$username ',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: remainingText,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    // If no @mention, just return the text
    return Text(text);
  }
}
