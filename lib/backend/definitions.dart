import 'package:json_annotation/json_annotation.dart';

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
  final String? creator;
  final String? title;
  final String? urlname;
  final String? about;
  final int? order;
  final ImageModel? cover;
  final ImageModel? card;
  final ImageModel? icon;
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
  final LiveStreamOfflineModel? offline;

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
  final dynamic category;
  final ImageModel? cover;
  final ImageModel? icon;
  final LiveStreamModel? liveStream;
  final List<dynamic>? subscriptionPlans;
  final bool? discoverable;
  final String? subscriberCountDisplay;
  final bool? incomeDisplay;
  final String? defaultChannel;
  final SocialLinksModel? socialLinks;
  final List<ChannelModel>? channels;
  final List<DiscordServerModel>? discordServers;
  final ImageModel? cardImage;

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
class BlogPostModelV3 {
  final String? id;
  final String? guid;
  final String? title;
  final String? text;
  final String? type;
  final dynamic channel;
  final List<String>? tags;
  final List<String>? attachmentOrder;
  final PostMetadataModel? metadata;
  final DateTime? releaseDate;
  final int? likes;
  final int? dislikes;
  final int? score;
  final int? comments;
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
