// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_packet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoundPacket _$SoundPacketFromJson(Map<String, dynamic> json) => SoundPacket(
      data: const Uint8ListJsonConverter().fromJson(json['data'] as List),
    );

Map<String, dynamic> _$SoundPacketToJson(SoundPacket instance) =>
    <String, dynamic>{
      'data': const Uint8ListJsonConverter().toJson(instance.data),
    };
