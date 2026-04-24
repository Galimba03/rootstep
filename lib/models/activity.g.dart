// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityAdapter extends TypeAdapter<Activity> {
  @override
  final int typeId = 0;

  @override
  Activity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Activity(
      id: fields[0] as String,
      dateTime: fields[1] as DateTime,
      distance: fields[2] as double,
      durationInSeconds: fields[3] as int,
      pace: fields[4] as String,
      altitude: fields[5] as double,
      route: (fields[6] as List)
          .map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List).cast<double>())
              .toList())
          .toList(),
      splits: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Activity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.distance)
      ..writeByte(3)
      ..write(obj.durationInSeconds)
      ..writeByte(4)
      ..write(obj.pace)
      ..writeByte(5)
      ..write(obj.altitude)
      ..writeByte(6)
      ..write(obj.route)
      ..writeByte(7)
      ..write(obj.splits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
