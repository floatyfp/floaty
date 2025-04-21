import 'package:floaty/backend/definitions.dart';

dynamic stringOrChannelModelFromJson(dynamic json) {
  if (json is String) return json;
  if (json is Map<String, dynamic>) return ChannelModel.fromJson(json);
  return null;
}

dynamic stringOrChannelModelToJson(dynamic value) {
  if (value is String) return value;
  if (value is ChannelModel) return value.toJson();
  return null;
}

dynamic imageModelFromJson(dynamic json) {
  if (json == null) return null;
  if (json is String) return json;
  if (json is Map<String, dynamic>) return ImageModel.fromJson(json);
  return null;
}

dynamic imageModelToJson(dynamic value) {
  if (value is String) return value;
  if (value is ImageModel) return value.toJson();
  return null;
}

dynamic socialLinksModelFromJson(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) return SocialLinksModel.fromJson(json);
  return null;
}

dynamic socialLinksModelToJson(dynamic value) {
  if (value is SocialLinksModel) return value.toJson();
  return null;
}

dynamic liveStreamModelFromJson(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) return LiveStreamModel.fromJson(json);
  return null;
}

dynamic liveStreamModelToJson(dynamic value) {
  if (value is LiveStreamModel) return value.toJson();
  return null;
}

List<ChannelModel>? channelModelListFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json
        .map((e) => e is ChannelModel
            ? e
            : (e is Map<String, dynamic> ? ChannelModel.fromJson(e) : null))
        .where((e) => e != null)
        .cast<ChannelModel>()
        .toList();
  }
  return null;
}

List<Map<String, dynamic>>? channelModelListToJson(List<ChannelModel>? value) {
  if (value == null) return null;
  return value.map((e) => e.toJson()).toList();
}

dynamic discordServerModelListFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json
        .map((e) =>
            e is Map<String, dynamic> ? DiscordServerModel.fromJson(e) : e)
        .toList();
  }
  return null;
}

dynamic discordServerModelListToJson(dynamic value) {
  if (value is List) {
    return value.map((e) => e is DiscordServerModel ? e.toJson() : e).toList();
  }
  return null;
}

dynamic liveStreamOfflineModelFromJson(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) {
    return LiveStreamOfflineModel.fromJson(json);
  }
  return null;
}

dynamic liveStreamOfflineModelToJson(dynamic value) {
  if (value is LiveStreamOfflineModel) return value.toJson();
  return null;
}

dynamic categoryFromJson(dynamic json) => json;
dynamic categoryToJson(dynamic value) => value;
