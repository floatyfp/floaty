import 'package:json_annotation/json_annotation.dart';
import 'package:floaty/features/api/utils/definitions_helpers.dart';

part 'definitions.g.dart';

@JsonSerializable()
class ChildImageModel {
  final int? width;
  final int? height;
  final String? path;

  ChildImageModel({
    this.width,
    this.height,
    this.path,
  });

  factory ChildImageModel.fromJson(Map<String, dynamic> json) =>
      _$ChildImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChildImageModelToJson(this);
}

@JsonSerializable()
class ImageModel {
  final int? width;
  final int? height;
  final String? path;
  final List<ChildImageModel>? childImages;

  ImageModel({
    this.width,
    this.height,
    this.path,
    this.childImages,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) =>
      _$ImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ImageModelToJson(this);
}

@JsonSerializable()
class DiscordServerModel {
  final String? id;
  final String? guildName;
  final String? guildIcon;
  final String? inviteLink;
  final String? inviteMode;

  DiscordServerModel({
    this.id,
    this.guildName,
    this.guildIcon,
    this.inviteLink,
    this.inviteMode,
  });

  factory DiscordServerModel.fromJson(Map<String, dynamic> json) =>
      _$DiscordServerModelFromJson(json);

  Map<String, dynamic> toJson() => _$DiscordServerModelToJson(this);
}

@JsonSerializable()
class ChannelModel {
  final String? id;
  @JsonKey(
      fromJson: stringOrChannelModelFromJson,
      toJson: stringOrChannelModelToJson)
  final dynamic creator;
  final String? title;
  final String? urlname;
  final String? about;
  final int? order;
  @JsonKey(fromJson: imageModelFromJson, toJson: imageModelToJson)
  final dynamic cover;
  @JsonKey(fromJson: imageModelFromJson, toJson: imageModelToJson)
  final dynamic card;
  @JsonKey(fromJson: imageModelFromJson, toJson: imageModelToJson)
  final dynamic icon;
  final SocialLinksModel? socialLinks;

  ChannelModel({
    this.id,
    this.creator,
    this.title,
    this.urlname,
    this.about,
    this.order,
    this.cover,
    this.card,
    this.icon,
    this.socialLinks,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) =>
      _$ChannelModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelModelToJson(this);
}

@JsonSerializable()
class SocialLinksModel {
  final dynamic discord;
  final dynamic twitter;
  final dynamic youtube;
  final dynamic facebook;
  final dynamic instagram;
  final dynamic website;

  SocialLinksModel({
    this.discord,
    this.twitter,
    this.youtube,
    this.facebook,
    this.instagram,
    this.website,
  });

  factory SocialLinksModel.fromJson(Map<String, dynamic> json) =>
      _$SocialLinksModelFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLinksModelToJson(this);
}

@JsonSerializable()
class LiveStreamOfflineModel {
  final String? title;
  final String? description;
  final ImageModel? thumbnail;

  LiveStreamOfflineModel({
    this.title,
    this.description,
    this.thumbnail,
  });

  factory LiveStreamOfflineModel.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamOfflineModelFromJson(json);

  Map<String, dynamic> toJson() => _$LiveStreamOfflineModelToJson(this);
}

@JsonSerializable()
class LiveStreamModel {
  final String? id;
  final String? title;
  final String? description;
  final ImageModel? thumbnail;
  final String? owner;
  final String? channel;
  final String? streamPath;
  @JsonKey(
      fromJson: liveStreamOfflineModelFromJson,
      toJson: liveStreamOfflineModelToJson)
  final dynamic offline;

  LiveStreamModel({
    this.id,
    this.title,
    this.description,
    this.thumbnail,
    this.owner,
    this.channel,
    this.streamPath,
    this.offline,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamModelFromJson(json);

  Map<String, dynamic> toJson() => _$LiveStreamModelToJson(this);
}

@JsonSerializable()
class CreatorModelV3 {
  final String? id;
  final dynamic owner;
  final String? title;
  final String? urlname;
  final String? description;
  final String? about;
  @JsonKey(fromJson: categoryFromJson, toJson: categoryToJson)
  final dynamic category;
  final ImageModel? cover;
  final ImageModel? icon;
  @JsonKey(fromJson: liveStreamModelFromJson, toJson: liveStreamModelToJson)
  final dynamic liveStream;
  final List<dynamic>? subscriptionPlans;
  final bool? discoverable;
  final String? subscriberCountDisplay;
  final bool? incomeDisplay;
  final String? defaultChannel;
  final SocialLinksModel? socialLinks;
  @JsonKey(fromJson: channelModelListFromJson, toJson: channelModelListToJson)
  final List<ChannelModel>? channels;
  @JsonKey(
      fromJson: discordServerModelListFromJson,
      toJson: discordServerModelListToJson)
  final dynamic discordServers;
  @JsonKey(fromJson: imageModelFromJson, toJson: imageModelToJson)
  final dynamic cardImage;

  CreatorModelV3({
    this.id,
    this.owner,
    this.title,
    this.urlname,
    this.description,
    this.about,
    this.category,
    this.cover,
    this.icon,
    this.liveStream,
    this.subscriptionPlans,
    this.discoverable,
    this.subscriberCountDisplay,
    this.incomeDisplay,
    this.defaultChannel,
    this.socialLinks,
    this.channels,
    this.discordServers,
    this.cardImage,
  });

  factory CreatorModelV3.fromJson(Map<String, dynamic> json) =>
      _$CreatorModelV3FromJson(json);

  Map<String, dynamic> toJson() => _$CreatorModelV3ToJson(this);
}

@JsonSerializable()
class PostMetadataModel {
  final bool? hasVideo;
  final int? videoCount;
  final double? videoDuration;
  final bool? hasAudio;
  final int? audioCount;
  final double? audioDuration;
  final bool? hasPicture;
  final int? pictureCount;
  final bool? hasGallery;
  final int? galleryCount;
  final bool? isFeatured;

  PostMetadataModel({
    this.hasVideo,
    this.videoCount,
    this.videoDuration,
    this.hasAudio,
    this.audioCount,
    this.audioDuration,
    this.hasPicture,
    this.pictureCount,
    this.hasGallery,
    this.galleryCount,
    this.isFeatured,
  });

  factory PostMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$PostMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostMetadataModelToJson(this);
}

@JsonSerializable()
class CreatorDiscoveryResponse {
  final String id;
  final String title;
  final String urlname;
  final String description;
  final String? about;
  final ImageModel icon;
  final List<String> channels;
  final List<BlogPostModelV3>? featuredBlogPosts;
  final Map<String, dynamic>?
      stats; // Making this nullable as it's not in the response

  CreatorDiscoveryResponse({
    required this.id,
    required this.title,
    required this.urlname,
    required this.description,
    this.about,
    required this.icon,
    required this.channels,
    this.featuredBlogPosts,
    this.stats,
  });

  factory CreatorDiscoveryResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatorDiscoveryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorDiscoveryResponseToJson(this);
}

@JsonSerializable()
class CreatorStats {
  final int posts;
  final int subscribers;
  final List<ChannelStats> channels;

  CreatorStats({
    required this.posts,
    required this.subscribers,
    required this.channels,
  });

  factory CreatorStats.fromJson(Map<String, dynamic> json) =>
      _$CreatorStatsFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorStatsToJson(this);
}

@JsonSerializable()
class ChannelStats {
  final String id;
  final int posts;

  ChannelStats({
    required this.id,
    required this.posts,
  });

  factory ChannelStats.fromJson(Map<String, dynamic> json) =>
      _$ChannelStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelStatsToJson(this);
}

@JsonSerializable()
class BlogPostModelV3 {
  final String? id;
  final String? guid;
  final String? title;
  final String? text;
  final String? type;
  @JsonKey(
      fromJson: stringOrChannelModelFromJson,
      toJson: stringOrChannelModelToJson)
  final dynamic channel;
  final List<String>? tags;
  final List<String>? attachmentOrder;
  final PostMetadataModel? metadata;
  final DateTime? releaseDate;
  final int? likes;
  final int? dislikes;
  final int? score;
  final int? comments;
  @JsonKey(
      fromJson: stringOrChannelModelFromJson,
      toJson: stringOrChannelModelToJson)
  final dynamic creator;
  final bool? wasReleasedSilently;
  final ImageModel? thumbnail;
  final bool? isAccessible;
  final List<dynamic>? videoAttachments;
  final List<dynamic>? audioAttachments;
  final List<dynamic>? pictureAttachments;
  final List<dynamic>? galleryAttachments;

  BlogPostModelV3({
    this.id,
    this.guid,
    this.title,
    this.text,
    this.type,
    this.channel,
    this.tags,
    this.attachmentOrder,
    this.metadata,
    this.releaseDate,
    this.likes,
    this.dislikes,
    this.score,
    this.comments,
    this.creator,
    this.wasReleasedSilently,
    this.thumbnail,
    this.isAccessible,
    this.videoAttachments,
    this.audioAttachments,
    this.pictureAttachments,
    this.galleryAttachments,
  });

  factory BlogPostModelV3.fromJson(Map<String, dynamic> json) =>
      _$BlogPostModelV3FromJson(json);

  Map<String, dynamic> toJson() => _$BlogPostModelV3ToJson(this);
}

@JsonSerializable()
class ContentCreatorListLastItems {
  final String? creatorId;
  final String? blogPostId;
  final bool? moreFetchable;

  ContentCreatorListLastItems({
    this.creatorId,
    this.blogPostId,
    this.moreFetchable,
  });

  factory ContentCreatorListLastItems.fromJson(Map<String, dynamic> json) =>
      _$ContentCreatorListLastItemsFromJson(json);

  Map<String, dynamic> toJson() => _$ContentCreatorListLastItemsToJson(this);
}

@JsonSerializable()
class ContentCreatorListV3Response {
  final List<BlogPostModelV3>? blogPosts;
  final List<ContentCreatorListLastItems>? lastElements;

  ContentCreatorListV3Response({
    this.blogPosts,
    this.lastElements,
  });

  factory ContentCreatorListV3Response.fromJson(Map<String, dynamic> json) =>
      _$ContentCreatorListV3ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ContentCreatorListV3ResponseToJson(this);
}

@JsonSerializable()
class UserSelfV3Response {
  final String? id;
  final String? username;
  final ImageModel? profileImage;
  final String? email;
  final String? displayName;
  final List<dynamic>? creators;
  final DateTime? scheduledDeletionDate;

  UserSelfV3Response({
    this.id,
    this.username,
    this.profileImage,
    this.email,
    this.displayName,
    this.creators,
    this.scheduledDeletionDate,
  });

  factory UserSelfV3Response.fromJson(Map<String, dynamic> json) =>
      _$UserSelfV3ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserSelfV3ResponseToJson(this);
}

@JsonSerializable()
class GetProgressResponse {
  final String? id;

  @JsonKey(defaultValue: 0)
  final int? progress;

  GetProgressResponse({
    this.id,
    this.progress,
  });

  factory GetProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$GetProgressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetProgressResponseToJson(this);
}

@JsonSerializable()
class HistoryModelV3 {
  final String? userId;
  final String? contentId;
  final String? contentType;
  final int? progress;
  final DateTime? updatedAt;
  final BlogPostModelV3 blogPost;

  HistoryModelV3({
    this.userId,
    this.contentId,
    this.contentType,
    this.progress,
    this.updatedAt,
    required this.blogPost,
  });

  factory HistoryModelV3.fromJson(Map<String, dynamic> json) =>
      _$HistoryModelV3FromJson(json);
  Map<String, dynamic> toJson() => _$HistoryModelV3ToJson(this);
}

@JsonSerializable()
class StatsModel {
  final dynamic totalSubcriberCount;
  final dynamic totalIncome;

  StatsModel({
    this.totalSubcriberCount,
    this.totalIncome,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) =>
      _$StatsModelFromJson(json);
  Map<String, dynamic> toJson() => _$StatsModelToJson(this);
}

@JsonSerializable()
class ContentPostV3Response {
  final String? id;
  final String? guid;
  final String? title;
  final String? text;
  final String? type;
  final ChannelModel? channel;
  @JsonKey(defaultValue: [])
  final List<String> tags;
  @JsonKey(defaultValue: [])
  final List<String> attachmentOrder;
  final PostMetadataModel? metadata;
  final DateTime? releaseDate;
  final int? likes;
  final int? dislikes;
  final int? score;
  final int? comments;
  final CreatorModelV2? creator;
  final bool? wasReleasedSilently;
  final ImageModel? thumbnail;
  final bool? isAccessible;
  @JsonKey(defaultValue: [])
  final List<dynamic> userInteraction;
  @JsonKey(defaultValue: [])
  final List<VideoAttachmentModel> videoAttachments;
  @JsonKey(defaultValue: [])
  final List<AudioAttachmentModel> audioAttachments;
  @JsonKey(defaultValue: [])
  final List<PictureAttachmentModel> pictureAttachments;
  @JsonKey(defaultValue: [])
  final List<dynamic> galleryAttachments;

  ContentPostV3Response({
    this.id,
    this.guid,
    this.title,
    this.text,
    this.type,
    this.channel,
    this.tags = const [],
    this.attachmentOrder = const [],
    this.metadata,
    this.releaseDate,
    this.likes,
    this.dislikes,
    this.score,
    this.comments,
    this.creator,
    this.wasReleasedSilently,
    this.thumbnail,
    this.isAccessible,
    this.userInteraction = const [],
    this.videoAttachments = const [],
    this.audioAttachments = const [],
    this.pictureAttachments = const [],
    this.galleryAttachments = const [],
  });

  factory ContentPostV3Response.fromJson(Map<String, dynamic> json) =>
      _$ContentPostV3ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ContentPostV3ResponseToJson(this);
}

@JsonSerializable()
class VideoAttachmentModel {
  final String id;
  final String guid;
  final String title;
  final String type;
  final String description;
  final DateTime? releaseDate;
  final double duration;
  final String creator;
  final int likes;
  final int dislikes;
  final int score;
  final bool isProcessing;
  final String primaryBlogPost;
  final ImageModel thumbnail;
  final bool isAccessible;

  VideoAttachmentModel({
    required this.id,
    required this.guid,
    required this.title,
    required this.type,
    required this.description,
    this.releaseDate,
    required this.duration,
    required this.creator,
    required this.likes,
    required this.dislikes,
    required this.score,
    required this.isProcessing,
    required this.primaryBlogPost,
    required this.thumbnail,
    required this.isAccessible,
  });

  factory VideoAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$VideoAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoAttachmentModelToJson(this);
}

@JsonSerializable()
class AudioAttachmentModel {
  final String id;
  final String guid;
  final String title;
  final String type;
  final String description;
  final int duration;
  final dynamic waveform;
  final String creator;
  final int likes;
  final int dislikes;
  final int score;
  final bool isProcessing;
  final String primaryBlogPost;
  final bool isAccessible;

  AudioAttachmentModel({
    required this.id,
    required this.guid,
    required this.title,
    required this.type,
    required this.description,
    required this.duration,
    required this.waveform,
    required this.creator,
    required this.likes,
    required this.dislikes,
    required this.score,
    required this.isProcessing,
    required this.primaryBlogPost,
    required this.isAccessible,
  });

  factory AudioAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$AudioAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$AudioAttachmentModelToJson(this);
}

@JsonSerializable()
class PictureAttachmentModel {
  final String id;
  final String guid;
  final String title;
  final String type;
  final String description;
  final int likes;
  final int dislikes;
  final int score;
  final bool isProcessing;
  final String creator;
  final String primaryBlogPost;
  final ImageModel thumbnail;
  final bool isAccessible;

  PictureAttachmentModel({
    required this.id,
    required this.guid,
    required this.title,
    required this.type,
    required this.description,
    required this.likes,
    required this.dislikes,
    required this.score,
    required this.isProcessing,
    required this.creator,
    required this.primaryBlogPost,
    required this.thumbnail,
    required this.isAccessible,
  });

  factory PictureAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$PictureAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PictureAttachmentModelToJson(this);
}

@JsonSerializable()
class CreatorModelV2 {
  final String? id;
  final String? owner;
  final String? title;
  final String? urlname;
  final String? description;
  final String? about;
  final String? category;
  final ImageModel? cover;
  final ImageModel? icon;
  final dynamic liveStream;
  @JsonKey(defaultValue: [])
  final List<dynamic> subscriptionPlans;
  final bool? discoverable;
  final String? subscriberCountDisplay;
  final bool? incomeDisplay;
  final String? defaultChannel;

  CreatorModelV2({
    this.id,
    this.owner,
    this.title,
    this.urlname,
    this.description,
    this.about,
    this.category,
    this.cover,
    this.icon,
    this.liveStream,
    this.subscriptionPlans = const [],
    this.discoverable,
    this.subscriberCountDisplay,
    this.incomeDisplay,
    this.defaultChannel,
  });

  factory CreatorModelV2.fromJson(Map<String, dynamic> json) =>
      _$CreatorModelV2FromJson(json);

  Map<String, dynamic> toJson() => _$CreatorModelV2ToJson(this);
}

class CommentModel {
  final String id;
  final String blogPost;
  final UserModel user;
  final String text;
  final String? replying;
  final DateTime postDate;
  final DateTime? editDate;
  final DateTime? pinDate;
  final int editCount;
  final bool isEdited;
  final int likes;
  final int dislikes;
  final int score;
  final UserInteractionModel interactionCounts;
  final int? totalReplies;
  final List<CommentModel>? replies;
  final UserInteractionModel? userInteraction;

  CommentModel({
    required this.id,
    required this.blogPost,
    required this.user,
    required this.text,
    this.replying,
    required this.postDate,
    this.editDate,
    this.pinDate,
    required this.editCount,
    required this.isEdited,
    required this.likes,
    required this.dislikes,
    required this.score,
    required this.interactionCounts,
    this.totalReplies,
    this.replies,
    this.userInteraction,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        blogPost: json['blogPost'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        text: json['text'] as String,
        replying: json['replying'] as String?,
        postDate: DateTime.parse(json['postDate'] as String),
        editDate: json['editDate'] == null
            ? null
            : DateTime.parse(json['editDate'] as String),
        pinDate: json['pinDate'] == null
            ? null
            : DateTime.parse(json['pinDate'] as String),
        editCount: (json['editCount'] as num).toInt(),
        isEdited: json['isEdited'] as bool,
        likes: (json['likes'] as num).toInt(),
        dislikes: (json['dislikes'] as num).toInt(),
        score: (json['score'] as num).toInt(),
        interactionCounts:
            UserInteractionModel.fromJson(json['interactionCounts']),
        totalReplies: (json['totalReplies'] as num?)?.toInt(),
        replies: (json['replies'] as List<dynamic>?)
            ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        userInteraction: json['userInteraction'] == null
            ? null
            : UserInteractionModel.fromJson(json['userInteraction']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'blogPost': blogPost,
        'user': user.toJson(),
        'text': text,
        'replying': replying,
        'postDate': postDate.toIso8601String(),
        'editDate': editDate?.toIso8601String(),
        'pinDate': pinDate?.toIso8601String(),
        'editCount': editCount,
        'isEdited': isEdited,
        'likes': likes,
        'dislikes': dislikes,
        'score': score,
        'interactionCounts': interactionCounts.toJson(),
        'totalReplies': totalReplies,
        'replies': replies?.map((e) => e.toJson()).toList(),
        'userInteraction': userInteraction?.toJson(),
      };
}

@JsonSerializable()
class UserInteractionModel {
  final int? like;
  final int? dislike;
  final String? value;

  const UserInteractionModel({
    this.like,
    this.dislike,
    this.value,
  });

  factory UserInteractionModel.fromJson(dynamic json) {
    if (json is String) {
      return UserInteractionModel(value: json);
    } else if (json is Map<String, dynamic>) {
      return UserInteractionModel(
        like: (json['like'] as num?)?.toInt(),
        dislike: (json['dislike'] as num?)?.toInt(),
      );
    }
    throw FormatException('Invalid JSON format for UserInteractionModel');
  }

  Map<String, dynamic> toJson() {
    if (value != null) {
      return {'value': value};
    }
    return {
      'like': like,
      'dislike': dislike,
    };
  }

  static const likeValue = UserInteractionModel(value: 'like');
  static const dislikeValue = UserInteractionModel(value: 'dislike');
}

@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final ImageModel profileImage;

  UserModel({
    required this.id,
    required this.username,
    required this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
