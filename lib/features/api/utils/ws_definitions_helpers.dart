import 'package:floaty/features/api/models/ws_definitions.dart';

dynamic stringOrPollFromJson(dynamic json) {
  if (json is String) return json;
  if (json is Map<String, dynamic>) return Poll.fromJson(json);
  return null;
}

dynamic stringOrPollToJson(dynamic value) {
  if (value is String) return value;
  if (value is Poll) return value.toJson();
  return null;
}

dynamic stringOrRunningTallyFromJson(dynamic json) {
  if (json is String) return json;
  if (json is Map<String, dynamic>) return RunningTally.fromJson(json);
  return null;
}

dynamic stringOrRunningTallyToJson(dynamic value) {
  if (value is String) return value;
  if (value is RunningTally) return value.toJson();
  return null;
}

dynamic stringOrTallyUpdateFromJson(dynamic json) {
  if (json is String) return json;
  if (json is Map<String, dynamic>) return TallyUpdate.fromJson(json);
  return null;
}

dynamic stringOrTallyUpdateToJson(dynamic value) {
  if (value is String) return value;
  if (value is TallyUpdate) return value.toJson();
  return null;
}
