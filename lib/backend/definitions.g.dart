// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'definitions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatorResponse _$CreatorResponseFromJson(Map<String, dynamic> json) =>
    CreatorResponse(
      id: json['id'] as String,
      owner: Owner.fromJson(json['owner'] as Map<String, dynamic>),
      title: json['title'] as String,
      urlname: json['urlname'] as String,
      description: json['description'] as String,
      about: json['about'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      cover: Image.fromJson(json['cover'] as Map<String, dynamic>),
      icon: Image.fromJson(json['icon'] as Map<String, dynamic>),
      liveStream:
          LiveStream.fromJson(json['liveStream'] as Map<String, dynamic>),
      subscriptionPlans: (json['subscriptionPlans'] as List<dynamic>)
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      discoverable: json['discoverable'] as bool,
      subscriberCountDisplay: json['subscriberCountDisplay'] as String,
      incomeDisplay: json['incomeDisplay'] as bool,
      defaultChannel: json['defaultChannel'] as String,
      socialLinks:
          SocialLinks.fromJson(json['socialLinks'] as Map<String, dynamic>),
      channels: (json['channels'] as List<dynamic>)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreatorResponseToJson(CreatorResponse instance) =>
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
      'socialLinks': instance.socialLinks,
      'channels': instance.channels,
    };

Owner _$OwnerFromJson(Map<String, dynamic> json) => Owner(
      id: json['id'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$OwnerToJson(Owner instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      id: json['id'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
    };

Image _$ImageFromJson(Map<String, dynamic> json) => Image(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      path: json['path'] as String,
      childImages: (json['childImages'] as List<dynamic>?)
          ?.map((e) => Image.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'path': instance.path,
      'childImages': instance.childImages,
    };

Thumbnail _$ThumbnailFromJson(Map<String, dynamic> json) => Thumbnail(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      path: json['path'] as String,
      childImages: (json['childImages'] as List<dynamic>?)
          ?.map((e) => Image.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ThumbnailToJson(Thumbnail instance) => <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'path': instance.path,
      'childImages': instance.childImages,
    };

LiveStream _$LiveStreamFromJson(Map<String, dynamic> json) => LiveStream(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnail: Thumbnail.fromJson(json['thumbnail'] as Map<String, dynamic>),
      owner: json['owner'] as String,
      channel: json['channel'] as String,
      streamPath: json['streamPath'] as String,
      offlineThumbnail:
          Thumbnail.fromJson(json['offlineThumbnail'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LiveStreamToJson(LiveStream instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnail': instance.thumbnail,
      'owner': instance.owner,
      'channel': instance.channel,
      'streamPath': instance.streamPath,
      'offlineThumbnail': instance.offlineThumbnail,
    };

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    SubscriptionPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      priceYearly: json['priceYearly'] as String,
      currency: json['currency'] as String,
      logo: json['logo'] as String?,
      interval: json['interval'] as String,
      featured: json['featured'] as bool,
      allowGrandfatheredAccess: json['allowGrandfatheredAccess'] as bool,
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'priceYearly': instance.priceYearly,
      'currency': instance.currency,
      'logo': instance.logo,
      'interval': instance.interval,
      'featured': instance.featured,
      'allowGrandfatheredAccess': instance.allowGrandfatheredAccess,
    };

SocialLinks _$SocialLinksFromJson(Map<String, dynamic> json) => SocialLinks(
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      website: json['website'] as String?,
      facebook: json['facebook'] as String?,
      youtube: json['youtube'] as String?,
    );

Map<String, dynamic> _$SocialLinksToJson(SocialLinks instance) =>
    <String, dynamic>{
      'instagram': instance.instagram,
      'twitter': instance.twitter,
      'website': instance.website,
      'facebook': instance.facebook,
      'youtube': instance.youtube,
    };

Channel _$ChannelFromJson(Map<String, dynamic> json) => Channel(
      id: json['id'] as String,
      creator: json['creator'] as String,
      title: json['title'] as String,
      urlname: json['urlname'] as String,
      about: json['about'] as String,
      order: (json['order'] as num).toInt(),
      cover: Image.fromJson(json['cover'] as Map<String, dynamic>),
      icon: Image.fromJson(json['icon'] as Map<String, dynamic>),
      socialLinks:
          SocialLinks.fromJson(json['socialLinks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChannelToJson(Channel instance) => <String, dynamic>{
      'id': instance.id,
      'creator': instance.creator,
      'title': instance.title,
      'urlname': instance.urlname,
      'about': instance.about,
      'order': instance.order,
      'cover': instance.cover,
      'icon': instance.icon,
      'socialLinks': instance.socialLinks,
    };

Creator _$CreatorFromJson(Map<String, dynamic> json) => Creator(
      id: json['id'] as String,
      owner: Owner.fromJson(json['owner'] as Map<String, dynamic>),
      title: json['title'] as String,
      urlname: json['urlname'] as String,
      description: json['description'] as String,
      about: json['about'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      cover: Image.fromJson(json['cover'] as Map<String, dynamic>),
      icon: Image.fromJson(json['icon'] as Map<String, dynamic>),
      liveStream:
          LiveStream.fromJson(json['liveStream'] as Map<String, dynamic>),
      subscriptionPlans: (json['subscriptionPlans'] as List<dynamic>)
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      discoverable: json['discoverable'] as bool,
      subscriberCountDisplay: json['subscriberCountDisplay'] as String,
      incomeDisplay: json['incomeDisplay'] as bool,
      defaultChannel: json['defaultChannel'] as String,
      socialLinks:
          SocialLinks.fromJson(json['socialLinks'] as Map<String, dynamic>),
      channels: (json['channels'] as List<dynamic>)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreatorToJson(Creator instance) => <String, dynamic>{
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
      'socialLinks': instance.socialLinks,
      'channels': instance.channels,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImage:
          Image.fromJson(json['profileImage'] as Map<String, dynamic>),
      email: json['email'] as String?,
      displayname: json['displayname'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profileImage': instance.profileImage,
      'email': instance.email,
      'displayname': instance.displayname,
    };
