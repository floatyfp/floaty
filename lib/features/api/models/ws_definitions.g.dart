// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

// ignore_for_file: unused_element

part of 'ws_definitions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Poll _$PollFromJson(Map<String, dynamic> json) => Poll(
      id: json['id'] as String,
      type: json['type'] as String,
      creator: json['creator'] as String,
      title: json['title'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      finalTallyApproximate: (json['finalTallyApproximate'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      finalTallyReal: (json['finalTallyReal'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      runningTally:
          RunningTally.fromJson(json['runningTally'] as Map<String, dynamic>),
      voted: json['voted'] as bool?,
      voteInfo: json['voteInfo'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PollToJson(Poll instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'creator': instance.creator,
      'title': instance.title,
      'options': instance.options,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'finalTallyApproximate': instance.finalTallyApproximate,
      'finalTallyReal': instance.finalTallyReal,
      'runningTally': instance.runningTally,
      'voted': instance.voted,
      'voteInfo': instance.voteInfo,
    };

RunningTally _$RunningTallyFromJson(Map<String, dynamic> json) => RunningTally(
      tick: (json['tick'] as num).toInt(),
      counts: (json['counts'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$RunningTallyToJson(RunningTally instance) =>
    <String, dynamic>{
      'tick': instance.tick,
      'counts': instance.counts,
    };

TallyUpdate _$TallyUpdateFromJson(Map<String, dynamic> json) => TallyUpdate(
      tick: stringOrRunningTallyFromJson(json['tick']),
      counts: (json['counts'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      pollId: json['pollId'] as String,
    );

Map<String, dynamic> _$TallyUpdateToJson(TallyUpdate instance) =>
    <String, dynamic>{
      'tick': stringOrRunningTallyToJson(instance.tick),
      'counts': instance.counts,
      'pollId': instance.pollId,
    };
