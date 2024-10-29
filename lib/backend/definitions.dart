import 'package:json_annotation/json_annotation.dart';

part 'definitions.g.dart';

@JsonSerializable()
class CreatorResponse {
  final String id;
  final Owner owner;
  final String title;
  final String urlname;
  final String description;
  final String about;
  final Category category;
  final Image cover;
  final Image icon;
  final LiveStream liveStream;
  final List<SubscriptionPlan> subscriptionPlans;
  final bool discoverable;
  final String subscriberCountDisplay;
  final bool incomeDisplay;
  final String defaultChannel;
  final SocialLinks socialLinks;
  final List<Channel> channels;

  CreatorResponse({
    required this.id,
    required this.owner,
    required this.title,
    required this.urlname,
    required this.description,
    required this.about,
    required this.category,
    required this.cover,
    required this.icon,
    required this.liveStream,
    required this.subscriptionPlans,
    required this.discoverable,
    required this.subscriberCountDisplay,
    required this.incomeDisplay,
    required this.defaultChannel,
    required this.socialLinks,
    required this.channels,
  });

  factory CreatorResponse.fromJson(Map<String, dynamic> json) {
    return CreatorResponse(
      id: json['id'],
      owner: Owner.fromJson(json['owner']),
      title: json['title'],
      urlname: json['urlname'],
      description: json['description'],
      about: json['about'],
      category: Category.fromJson(json['category']),
      cover: Image.fromJson(json['cover']),
      icon: Image.fromJson(json['icon']),
      liveStream: LiveStream.fromJson(json['liveStream']),
      subscriptionPlans: (json['subscriptionPlans'] as List)
          .map((i) => SubscriptionPlan.fromJson(i))
          .toList(),
      discoverable: json['discoverable'],
      subscriberCountDisplay: json['subscriberCountDisplay'],
      incomeDisplay: json['incomeDisplay'],
      defaultChannel: json['defaultChannel'],
      socialLinks: SocialLinks.fromJson(json['socialLinks']),
      channels: (json['channels'] as List)
          .map((i) => Channel.fromJson(i))
          .toList(),
    );
  }
}

@JsonSerializable()
class Owner {
  final String id;
  final String username;

  Owner({required this.id, required this.username});

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      username: json['username'],
    );
  }
}

@JsonSerializable()
class Category {
  final String id;
  final String title;

  Category({required this.id, required this.title});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      title: json['title'],
    );
  }
}

@JsonSerializable()
class Image {
  final int width;
  final int height;
  final String path;
  final List<Image>? childImages;

  Image({required this.width, required this.height, required this.path, this.childImages});

  factory Image.fromJson(Map<String, dynamic> json) {
    var childImagesList = (json['childImages'] as List?)?.map((i) => Image.fromJson(i)).toList();
    return Image(
      width: json['width'],
      height: json['height'],
      path: json['path'],
      childImages: childImagesList,
    );
  }
}

@JsonSerializable()
class Thumbnail {
  final int width;
  final int height;
  final String path;
  final List<Image>? childImages;

  Thumbnail({required this.width, required this.height, required this.path, this.childImages});

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    var childImagesList = (json['childImages'] as List?)?.map((i) => Image.fromJson(i)).toList();
    return Thumbnail(
      width: json['width'],
      height: json['height'],
      path: json['path'],
      childImages: childImagesList,
    );
  }
}

@JsonSerializable()
class LiveStream {
  final String id;
  final String title;
  final String description;
  final Thumbnail thumbnail;
  final String owner;
  final String channel;
  final String streamPath;
  final Thumbnail offlineThumbnail;

  LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.owner,
    required this.channel,
    required this.streamPath,
    required this.offlineThumbnail,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      thumbnail: Thumbnail.fromJson(json['thumbnail']),
      owner: json['owner'],
      channel: json['channel'],
      streamPath: json['streamPath'],
      offlineThumbnail: Thumbnail.fromJson(json['offline']['thumbnail']),
    );
  }
}

@JsonSerializable()
class SubscriptionPlan {
  final String id;
  final String title;
  final String description;
  final String price;
  final String priceYearly;
  final String currency;
  final String? logo;
  final String interval;
  final bool featured;
  final bool allowGrandfatheredAccess;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceYearly,
    required this.currency,
    this.logo,
    required this.interval,
    required this.featured,
    required this.allowGrandfatheredAccess,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'],
      priceYearly: json['priceYearly'],
      currency: json['currency'],
      logo: json['logo'],
      interval: json['interval'],
      featured: json['featured'],
      allowGrandfatheredAccess: json['allowGrandfatheredAccess'],
    );
  }
}

@JsonSerializable()
class SocialLinks {
  final String? instagram;
  final String? twitter;
  final String? website;
  final String? facebook;
  final String? youtube;

  SocialLinks({this.instagram, this.twitter, this.website, this.facebook, this.youtube});

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'],
      twitter: json['twitter'],
      website: json['website'],
      facebook: json['facebook'],
      youtube: json['youtube'],
    );
  }
}

@JsonSerializable()
class Channel {
  final String id;
  final String creator;
  final String title;
  final String urlname;
  final String about;
  final int order;
  final Image cover;
  final Image icon;
  final SocialLinks socialLinks;

  Channel({
    required this.id,
    required this.creator,
    required this.title,
    required this.urlname,
    required this.about,
    required this.order,
    required this.cover,
    required this.icon,
    required this.socialLinks,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      creator: json['creator'],
      title: json['title'],
      urlname: json['urlname'],
      about: json['about'],
      order: json['order'],
      cover: Image.fromJson(json['cover']),
      icon: Image.fromJson(json['icon']),
      socialLinks: SocialLinks.fromJson(json['socialLinks']),
    );
  }
}

@JsonSerializable()
class Creator {
  final String id;
  final Owner owner;
  final String title;
  final String urlname;
  final String description;
  final String about;
  final Category category;
  final Image cover;
  final Image icon;
  final LiveStream liveStream;
  final List<SubscriptionPlan> subscriptionPlans;
  final bool discoverable;
  final String subscriberCountDisplay;
  final bool incomeDisplay;
  final String defaultChannel;
  final SocialLinks socialLinks;
  final List<Channel> channels;

  Creator({
    required this.id,
    required this.owner,
    required this.title,
    required this.urlname,
    required this.description,
    required this.about,
    required this.category,
    required this.cover,
    required this.icon,
    required this.liveStream,
    required this.subscriptionPlans,
    required this.discoverable,
    required this.subscriberCountDisplay,
    required this.incomeDisplay,
    required this.defaultChannel,
    required this.socialLinks,
    required this.channels,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    var subscriptionPlansList = (json['subscriptionPlans'] as List)
        .map((i) => SubscriptionPlan.fromJson(i))
        .toList();

    var channelsList = (json['channels'] as List)
        .map((i) => Channel.fromJson(i))
        .toList();

    return Creator(
      id: json['id'],
      owner: Owner.fromJson(json['owner']),
      title: json['title'],
      urlname: json['urlname'],
      description: json['description'],
      about: json['about'],
      category: Category.fromJson(json['category']),
      cover: Image.fromJson(json['cover']),
      icon: Image.fromJson(json['icon']),
      liveStream: LiveStream.fromJson(json['liveStream']),
      subscriptionPlans: subscriptionPlansList,
      discoverable: json['discoverable'],
      subscriberCountDisplay: json['subscriberCountDisplay'],
      incomeDisplay: json['incomeDisplay'],
      defaultChannel: json['defaultChannel'],
      socialLinks: SocialLinks.fromJson(json['socialLinks']),
      channels: channelsList,
    );
  }
}

