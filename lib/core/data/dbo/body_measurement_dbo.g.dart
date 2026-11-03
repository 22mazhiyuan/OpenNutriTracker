// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMeasurementDBOAdapter extends TypeAdapter<BodyMeasurementDBO> {
  @override
  final typeId = 24;

  @override
  BodyMeasurementDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMeasurementDBO(
      date: fields[0] as DateTime,
      metricIndex: (fields[1] as num).toInt(),
      value: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BodyMeasurementDBO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.metricIndex)
      ..writeByte(2)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurementDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
