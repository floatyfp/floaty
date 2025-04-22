import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/shared/utils/time/difference.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BlogPostCard extends StatelessWidget {
  final BlogPostModelV3 blogPost;
  final GetProgressResponse? response;
  final double computedValue;
  final String formattedDuration;
  final String mediaTypeLabel;
  final String relativeTime;

  BlogPostCard(this.blogPost, {this.response, super.key})
      : computedValue = (response?.progress ?? 0) / 100,
        formattedDuration = _formatDuration(blogPost),
        mediaTypeLabel = _getMediaTypeLabel(blogPost),
        relativeTime = _getRelativeTime(blogPost.releaseDate);

  static String _formatDuration(BlogPostModelV3 blogPost) {
    final duration = Duration(
        seconds: (blogPost.metadata?.videoDuration ??
                blogPost.metadata?.audioDuration ??
                0)
            .toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String _getMediaTypeLabel(BlogPostModelV3 blogPost) {
    final meta = blogPost.metadata;
    final typeHierarchy = [
      if (meta?.hasVideo == true) 'Video',
      if (meta?.hasAudio == true) 'Audio',
      if (meta?.hasPicture == true) 'Image',
      if (meta?.hasGallery == true) 'Gallery',
      'Text'
    ];
    return typeHierarchy.first;
  }

  static String _getRelativeTime(DateTime? dateTime) =>
      dateTime?.relativeTime ?? 'Unknown date';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => blogPost.isAccessible == true
            ? context.push('/post/${blogPost.id}')
            : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth * 0.08;
            final fontSize = constraints.maxWidth * 0.04;

            return Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnailSection(context, constraints, fontSize),
                  const SizedBox(height: 8),
                  _buildFooterSection(iconSize, fontSize, context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnailSection(
      BuildContext context, BoxConstraints constraints, double fontSize) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: blogPost.thumbnail?.path != null
                ? FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: blogPost.thumbnail?.path ?? '',
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                  )
                : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
          ),

          // Duration label
          if (blogPost.metadata?.hasAudio == true ||
              blogPost.metadata?.hasVideo == true)
            Positioned(
              bottom: response != null ? 12 : 8,
              right: 8,
              child: _InfoBubble(
                text: formattedDuration,
                fontSize: fontSize,
              ),
            ),

          // Progress indicator
          if (response != null)
            Positioned(
              bottom: 2.5,
              left: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 5,
                  value: computedValue,
                ),
              ),
            ),

          // Media type label
          Positioned(
            bottom: response != null ? 12 : 8,
            left: 8,
            child: _InfoBubble(
              text: mediaTypeLabel,
              fontSize: fontSize,
            ),
          ),

          // Lock icon
          if (blogPost.isAccessible == false)
            Center(
              child: Container(
                padding: EdgeInsets.all(constraints.maxWidth * 0.06),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.lock,
                  size: constraints.maxWidth * 0.15,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(
      double iconSize, double fontSize, BuildContext context) {
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel icon
          if (blogPost.channel is ChannelModel)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: blogPost.channel?.icon?.path ??
                    blogPost.creator.icon?.path ??
                    '',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
          if (blogPost.channel is! ChannelModel &&
              blogPost.creator.icon != null &&
              blogPost.creator.icon is ImageModel)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: blogPost.creator.icon?.path ?? '',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  blogPost.title ?? '',
                  stepGranularity: 0.25,
                  minFontSize: 10,
                  maxFontSize: 13,
                  textScaleFactor: 0.95,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize * 1.150, // 0.047 of constraints
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  '${blogPost.channel is ChannelModel ? blogPost.channel?.title ?? '' : blogPost.creator.title ?? ''} • $relativeTime',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    fontSize: fontSize,
                  ),
                  stepGranularity: 0.25,
                  minFontSize: 2,
                  maxFontSize: 10,
                  textScaleFactor: 0.95,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBubble extends StatelessWidget {
  final String text;
  final double fontSize;

  const _InfoBubble({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
