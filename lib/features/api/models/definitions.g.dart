// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'definitions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChildImageModel _$ChildImageModelFromJson(Map<String, dynamic> json) =>
    ChildImageModel(
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      path: json['path'] as String?,
    );

Map<String, dynamic> _$ChildImageModelToJson(ChildImageModel instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'path': instance.path,
    };

ImageModel _$ImageModelFromJson(Map<String, dynamic> json) => ImageModel(
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      path: json['path'] as String?,
      childImages: (json['childImages'] as List<dynamic>?)
          ?.map((e) => ChildImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ImageModelToJson(ImageModel instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'path': instance.path,
      'childImages': instance.childImages,
    };

DiscordServerModel _$DiscordServerModelFromJson(Map<String, dynamic> json) =>
    DiscordServerModel(
      id: json['id'] as String?,
      guildName: json['guildName'] as String?,
      guildIcon: json['guildIcon'] as String?,
      inviteLink: json['inviteLink'] as String?,
      inviteMode: json['inviteMode'] as String?,
    );

Map<String, dynamic> _$DiscordServerModelToJson(DiscordServerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guildName': instance.guildName,
      'guildIcon': instance.guildIcon,
      'inviteLink': instance.inviteLink,
      'inviteMode': instance.inviteMode,
    };

ChannelModel _$ChannelModelFromJson(Map<String, dynamic> json) => ChannelModel(
      id: json['id'] as String?,
      creator: stringOrChannelModelFromJson(json['creator']),
      title: json['title'] as String?,
      urlname: json['urlname'] as String?,
      about: json['about'] as String?,
      order: (json['order'] as num?)?.toInt(),
      cover: imageModelFromJson(json['cover']),
      card: imageModelFromJson(json['card']),
      icon: imageModelFromJson(json['icon']),
      socialLinks: json['socialLinks'] == null
          ? null
          : SocialLinksModel.fromJson(
              json['socialLinks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChannelModelToJson(ChannelModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'creator': stringOrChannelModelToJson(instance.creator),
      'title': instance.title,
      'urlname': instance.urlname,
      'about': instance.about,
      'order': instance.order,
      'cover': imageModelToJson(instance.cover),
      'card': imageModelToJson(instance.card),
      'icon': imageModelToJson(instance.icon),
      'socialLinks': instance.socialLinks,
    };

SocialLinksModel _$SocialLinksModelFromJson(Map<String, dynamic> json) =>
    SocialLinksModel(
      discord: json['discord'],
      twitter: json['twitter'],
      youtube: json['youtube'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      website: json['website'],
    );

Map<String, dynamic> _$SocialLinksModelToJson(SocialLinksModel instance) =>
    <String, dynamic>{
      'discord': instance.discord,
      'twitter': instance.twitter,
      'youtube': instance.youtube,
      'facebook': instance.facebook,
      'instagram': instance.instagram,
      'website': instance.website,
    };

LiveStreamOfflineModel _$LiveStreamOfflineModelFromJson(
        Map<String, dynamic> json) =>
    LiveStreamOfflineModel(
      title: json['title'] as String?,
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] == null
          ? null
          : ImageModel.fromJson(json['thumbnail'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LiveStreamOfflineModelToJson(
        LiveStreamOfflineModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'thumbnail': instance.thumbnail,
    };

LiveStreamModel _$LiveStreamModelFromJson(Map<String, dynamic> json) =>
    LiveStreamModel(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] == null
          ? null
          : ImageModel.fromJson(json['thumbnail'] as Map<String, dynamic>),
      owner: json['owner'] as String?,
      channel: json['channel'] as String?,
      streamPath: json['streamPath'] as String?,
      offline: liveStreamOfflineModelFromJson(json['offline']),
    );

Map<String, dynamic> _$LiveStreamModelToJson(LiveStreamModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnail': instance.thumbnail,
      'owner': instance.owner,
      'channel': instance.channel,
      'streamPath': instance.streamPath,
      'offline': liveStreamOfflineModelToJson(instance.offline),
    };

CreatorModelV3 _$CreatorModelV3FromJson(Map<String, dynamic> json) =>
    CreatorModelV3(
      id: json['id'] as String?,
      owner: json['owner'],
      title: json['title'] as String?,
      urlname: json['urlname'] as String?,
      description: json['description'] as String?,
      about: json['about'] as String?,
      category: categoryFromJson(json['category']),
      cover: json['cover'] == null
          ? null
          : ImageModel.fromJson(json['cover'] as Map<String, dynamic>),
      icon: json['icon'] == null
          ? null
          : ImageModel.fromJson(json['icon'] as Map<String, dynamic>),
      liveStream: liveStreamModelFromJson(json['liveStream']),
      subscriptionPlans: json['subscriptionPlans'] as List<dynamic>?,
      discoverable: json['discoverable'] as bool?,
      subscriberCountDisplay: json['subscriberCountDisplay'] as String?,
      incomeDisplay: json['incomeDisplay'] as bool?,
      defaultChannel: json['defaultChannel'] as String?,
      socialLinks: json['socialLinks'] == null
          ? null
          : SocialLinksModel.fromJson(
              json['socialLinks'] as Map<String, dynamic>),
      channels: channelModelListFromJson(json['channels']),
      discordServers: discordServerModelListFromJson(json['discordServers']),
      cardImage: imageModelFromJson(json['cardImage']),
    );

Map<String, dynamic> _$CreatorModelV3ToJson(CreatorModelV3 instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner': instance.owner,
      'title': instance.title,
      'urlname': instance.urlname,
      'description': instance.description,
      'about': instance.about,
      'category': categoryToJson(instance.category),
      'cover': instance.cover,
      'icon': instance.icon,
      'liveStream': liveStreamModelToJson(instance.liveStream),
      'subscriptionPlans': instance.subscriptionPlans,
      'discoverable': instance.discoverable,
      'subscriberCountDisplay': instance.subscriberCountDisplay,
      'incomeDisplay': instance.incomeDisplay,
      'defaultChannel': instance.defaultChannel,
      'socialLinks': instance.socialLinks,
      'channels': channelModelListToJson(instance.channels),
      'discordServers': discordServerModelListToJson(instance.discordServers),
      'cardImage': imageModelToJson(instance.cardImage),
    };

PostMetadataModel _$PostMetadataModelFromJson(Map<String, dynamic> json) =>
    PostMetadataModel(
      hasVideo: json['hasVideo'] as bool?,
      videoCount: (json['videoCount'] as num?)?.toInt(),
      videoDuration: (json['videoDuration'] as num?)?.toDouble(),
      hasAudio: json['hasAudio'] as bool?,
      audioCount: (json['audioCount'] as num?)?.toInt(),
      audioDuration: (json['audioDuration'] as num?)?.toDouble(),
      hasPicture: json['hasPicture'] as bool?,
      pictureCount: (json['pictureCount'] as num?)?.toInt(),
      hasGallery: json['hasGallery'] as bool?,
      galleryCount: (json['galleryCount'] as num?)?.toInt(),
      isFeatured: json['isFeatured'] as bool?,
    );

Map<String, dynamic> _$PostMetadataModelToJson(PostMetadataModel instance) =>
    <String, dynamic>{
      'hasVideo': instance.hasVideo,
      'videoCount': instance.videoCount,
      'videoDuration': instance.videoDuration,
      'hasAudio': instance.hasAudio,
      'audioCount': instance.audioCount,
      'audioDuration': instance.audioDuration,
      'hasPicture': instance.hasPicture,
      'pictureCount': instance.pictureCount,
      'hasGallery': instance.hasGallery,
      'galleryCount': instance.galleryCount,
      'isFeatured': instance.isFeatured,
    };

BlogPostModelV3 _$BlogPostModelV3FromJson(Map<String, dynamic> json) =>
    BlogPostModelV3(
      id: json['id'] as String?,
      guid: json['guid'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
      type: json['type'] as String?,
      channel: stringOrChannelModelFromJson(json['channel']),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      attachmentOrder: (json['attachmentOrder'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] == null
          ? null
          : PostMetadataModel.fromJson(
              json['metadata'] as Map<String, dynamic>),
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      likes: (json['likes'] as num?)?.toInt(),
      dislikes: (json['dislikes'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt(),
      comments: (json['comments'] as num?)?.toInt(),
      creator: stringOrChannelModelFromJson(json['creator']),
      wasReleasedSilently: json['wasReleasedSilently'] as bool?,
      thumbnail: json['thumbnail'] == null
          ? null
          : ImageModel.fromJson(json['thumbnail'] as Map<String, dynamic>),
      isAccessible: json['isAccessible'] as bool?,
      videoAttachments: json['videoAttachments'] as List<dynamic>?,
      audioAttachments: json['audioAttachments'] as List<dynamic>?,
      pictureAttachments: json['pictureAttachments'] as List<dynamic>?,
      galleryAttachments: json['galleryAttachments'] as List<dynamic>?,
    );

Map<String, dynamic> _$BlogPostModelV3ToJson(BlogPostModelV3 instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guid': instance.guid,
      'title': instance.title,
      'text': instance.text,
      'type': instance.type,
      'channel': stringOrChannelModelToJson(instance.channel),
      'tags': instance.tags,
      'attachmentOrder': instance.attachmentOrder,
      'metadata': instance.metadata,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'likes': instance.likes,
      'dislikes': instance.dislikes,
      'score': instance.score,
      'comments': instance.comments,
      'creator': stringOrChannelModelToJson(instance.creator),
      'wasReleasedSilently': instance.wasReleasedSilently,
      'thumbnail': instance.thumbnail,
      'isAccessible': instance.isAccessible,
      'videoAttachments': instance.videoAttachments,
      'audioAttachments': instance.audioAttachments,
      'pictureAttachments': instance.pictureAttachments,
      'galleryAttachments': instance.galleryAttachments,
    };

ContentCreatorListLastItems _$ContentCreatorListLastItemsFromJson(
        Map<String, dynamic> json) =>
    ContentCreatorListLastItems(
      creatorId: json['creatorId'] as String?,
      blogPostId: json['blogPostId'] as String?,
      moreFetchable: json['moreFetchable'] as bool?,
    );

Map<String, dynamic> _$ContentCreatorListLastItemsToJson(
        ContentCreatorListLastItems instance) =>
    <String, dynamic>{
      'creatorId': instance.creatorId,
      'blogPostId': instance.blogPostId,
      'moreFetchable': instance.moreFetchable,
    };

ContentCreatorListV3Response _$ContentCreatorListV3ResponseFromJson(
        Map<String, dynamic> json) =>
    ContentCreatorListV3Response(
      blogPosts: (json['blogPosts'] as List<dynamic>?)
          ?.map((e) => BlogPostModelV3.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastElements: (json['lastElements'] as List<dynamic>?)
          ?.map((e) =>
              ContentCreatorListLastItems.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContentCreatorListV3ResponseToJson(
        ContentCreatorListV3Response instance) =>
    <String, dynamic>{
      'blogPosts': instance.blogPosts,
      'lastElements': instance.lastElements,
    };

UserSelfV3Response _$UserSelfV3ResponseFromJson(Map<String, dynamic> json) =>
    UserSelfV3Response(
      id: json['id'] as String?,
      username: json['username'] as String?,
      profileImage: json['profileImage'] == null
          ? null
          : ImageModel.fromJson(json['profileImage'] as Map<String, dynamic>),
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      creators: json['creators'] as List<dynamic>?,
      scheduledDeletionDate: json['scheduledDeletionDate'] == null
          ? null
          : DateTime.parse(json['scheduledDeletionDate'] as String),
    );

Map<String, dynamic> _$UserSelfV3ResponseToJson(UserSelfV3Response instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profileImage': instance.profileImage,
      'email': instance.email,
      'displayName': instance.displayName,
      'creators': instance.creators,
      'scheduledDeletionDate':
          instance.scheduledDeletionDate?.toIso8601String(),
    };

GetProgressResponse _$GetProgressResponseFromJson(Map<String, dynamic> json) =>
    GetProgressResponse(
      id: json['id'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GetProgressResponseToJson(
        GetProgressResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'progress': instance.progress,
    };

HistoryModelV3 _$HistoryModelV3FromJson(Map<String, dynamic> json) =>
    HistoryModelV3(
      userId: json['userId'] as String?,
      contentId: json['contentId'] as String?,
      contentType: json['contentType'] as String?,
      progress: (json['progress'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      blogPost:
          BlogPostModelV3.fromJson(json['blogPost'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HistoryModelV3ToJson(HistoryModelV3 instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'contentId': instance.contentId,
      'contentType': instance.contentType,
      'progress': instance.progress,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'blogPost': instance.blogPost,
    };

StatsModel _$StatsModelFromJson(Map<String, dynamic> json) => StatsModel(
      totalSubcriberCount: json['totalSubcriberCount'],
      totalIncome: json['totalIncome'],
    );

Map<String, dynamic> _$StatsModelToJson(StatsModel instance) =>
    <String, dynamic>{
      'totalSubcriberCount': instance.totalSubcriberCount,
      'totalIncome': instance.totalIncome,
    };

ContentPostV3Response _$ContentPostV3ResponseFromJson(
        Map<String, dynamic> json) =>
    ContentPostV3Response(
      id: json['id'] as String?,
      guid: json['guid'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
      type: json['type'] as String?,
      channel: json['channel'] == null
          ? null
          : ChannelModel.fromJson(json['channel'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      attachmentOrder: (json['attachmentOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] == null
          ? null
          : PostMetadataModel.fromJson(
              json['metadata'] as Map<String, dynamic>),
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      likes: (json['likes'] as num?)?.toInt(),
      dislikes: (json['dislikes'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt(),
      comments: (json['comments'] as num?)?.toInt(),
      creator: json['creator'] == null
          ? null
          : CreatorModelV2.fromJson(json['creator'] as Map<String, dynamic>),
      wasReleasedSilently: json['wasReleasedSilently'] as bool?,
      thumbnail: json['thumbnail'] == null
          ? null
          : ImageModel.fromJson(json['thumbnail'] as Map<String, dynamic>),
      isAccessible: json['isAccessible'] as bool?,
      userInteraction: json['userInteraction'] as List<dynamic>? ?? [],
      videoAttachments: (json['videoAttachments'] as List<dynamic>?)
              ?.map((e) =>
                  VideoAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      audioAttachments: (json['audioAttachments'] as List<dynamic>?)
              ?.map((e) =>
                  AudioAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pictureAttachments: (json['pictureAttachments'] as List<dynamic>?)
              ?.map((e) =>
                  PictureAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      galleryAttachments: json['galleryAttachments'] as List<dynamic>? ?? [],
    );

Map<String, dynamic> _$ContentPostV3ResponseToJson(
        ContentPostV3Response instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guid': instance.guid,
      'title': instance.title,
      'text': instance.text,
      'type': instance.type,
      'channel': instance.channel,
      'tags': instance.tags,
      'attachmentOrder': instance.attachmentOrder,
      'metadata': instance.metadata,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'likes': instance.likes,
      'dislikes': instance.dislikes,
      'score': instance.score,
      'comments': instance.comments,
      'creator': instance.creator,
      'wasReleasedSilently': instance.wasReleasedSilently,
      'thumbnail': instance.thumbnail,
      'isAccessible': instance.isAccessible,
      'userInteraction': instance.userInteraction,
      'videoAttachments': instance.videoAttachments,
      'audioAttachments': instance.audioAttachments,
      'pictureAttachments': instance.pictureAttachments,
      'galleryAttachments': instance.galleryAttachments,
    };

VideoAttachmentModel _$VideoAttachmentModelFromJson(
        Map<String, dynamic> json) =>
    VideoAttachmentModel(
      id: json['id'] as String,
      guid: json['guid'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      duration: (json['duration'] as num).toDouble(),
      creator: json['creator'] as String,
      likes: (json['likes'] as num).toInt(),
      dislikes: (json['dislikes'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      isProcessing: json['isProcessing'] as bool,
      primaryBlogPost: json['primaryBlogPost'] as String,
      thumbnail: ImageModel.fromJson(json['thumbnail'] as Map<String, dynamic>),
      isAccessible: json['isAccessible'] as bool,
    );

Map<String, dynamic> _$VideoAttachmentModelToJson(
        VideoAttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guid': instance.guid,
      'title': instance.title,
      'type': instance.type,
      'description': instance.description,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'duration': instance.duration,
      'creator': instance.creator,
      'likes': instance.likes,
      'dislikes': instance.dislikes,
      'score': instance.score,
      'isProcessing': instance.isProcessing,
      'primaryBlogPost': instance.primaryBlogPost,
      'thumbnail': instance.thumbnail,
      'isAccessible': instance.isAccessible,
    };

AudioAttachmentModel _$AudioAttachmentModelFromJson(
        Map<String, dynamic> json) =>
    AudioAttachmentModel(
      id: json['id'] as String,
      guid: json['guid'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      duration: (json['duration'] as num).toInt(),
      waveform: json['waveform'],
      creator: json['creator'] as String,
      likes: (json['likes'] as num).toInt(),
      dislikes: (json['dislikes'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      isProcessing: json['isProcessing'] as bool,
      primaryBlogPost: json['primaryBlogPost'] as String,
      isAccessible: json['isAccessible'] as bool,
    );

Map<String, dynamic> _$AudioAttachmentModelToJson(
        AudioAttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guid': instance.guid,
      'title': instance.title,
      'type': instance.type,
      'description': instance.description,
      'duration': instance.duration,
      'waveform': instance.waveform,
      'creator': instance.creator,
      'likes': instance.likes,
      'dislikes': instance.dislikes,
      'score': instance.score,
      'isProcessing': instance.isProcessing,
      'primaryBlogPost': instance.primaryBlogPost,
      'isAccessible': instance.isAccessible,
    };

PictureAttachmentModel _$PictureAttachmentModelFromJson(
        Map<String, dynamic> json) =>
    PictureAttachmentModel(
      id: json['id'] as String,
      guid: json['guid'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      likes: (json['likes'] as num).toInt(),
      dislikes: (json['dislikes'] as num).toInt(),
      score: (json['score'] as num).toInt(),
      isProcessing: json['isProcessing'] as bool,
      creator: json['creator'] as String,
      primaryBlogPost: json['primaryBlogPost'] as String,
      thumbnail: ImageModel.fromJson(json['thumbnail'] as Map<String, dynamic>),
      isAccessible: json['isAccessible'] as bool,
    );

Map<String, dynamic> _$PictureAttachmentModelToJson(
        PictureAttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guid': instance.guid,
      'title': instance.title,
      'type': instance.type,
      'description': instance.description,
      'likes': instance.likes,
      'dislikes': instance.dislikes,
      'score': instance.score,
      'isProcessing': instance.isProcessing,
      'creator': instance.creator,
      'primaryBlogPost': instance.primaryBlogPost,
      'thumbnail': instance.thumbnail,
      'isAccessible': instance.isAccessible,
    };

CreatorModelV2 _$CreatorModelV2FromJson(Map<String, dynamic> json) =>
    CreatorModelV2(
      id: json['id'] as String?,
      owner: json['owner'] as String?,
      title: json['title'] as String?,
      urlname: json['urlname'] as String?,
      description: json['description'] as String?,
      about: json['about'] as String?,
      category: json['category'] as String?,
      cover: json['cover'] == null
          ? null
          : ImageModel.fromJson(json['cover'] as Map<String, dynamic>),
      icon: json['icon'] == null
          ? null
          : ImageModel.fromJson(json['icon'] as Map<String, dynamic>),
      liveStream: json['liveStream'],
      subscriptionPlans: json['subscriptionPlans'] as List<dynamic>? ?? [],
      discoverable: json['discoverable'] as bool?,
      subscriberCountDisplay: json['subscriberCountDisplay'] as String?,
      incomeDisplay: json['incomeDisplay'] as bool?,
      defaultChannel: json['defaultChannel'] as String?,
    );

Map<String, dynamic> _$CreatorModelV2ToJson(CreatorModelV2 instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner': instance.owner,
      'title': instance.title,
      'urlname': instance.urlname,
      'description': instance.description,
      'about': instance.about,
      'category': instance.category,
      'cover': instance.cover,
      'icon': instance.icon,
      'liveStream': instance.liveStream,
      'subscriptionPlans': instance.subscriptionPlans,
      'discoverable': instance.discoverable,
      'subscriberCountDisplay': instance.subscriberCountDisplay,
      'incomeDisplay': instance.incomeDisplay,
      'defaultChannel': instance.defaultChannel,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImage:
          ImageModel.fromJson(json['profileImage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profileImage': instance.profileImage,
    };
