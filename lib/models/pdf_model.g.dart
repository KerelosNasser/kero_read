// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfModelAdapter extends TypeAdapter<PdfModel> {
  @override
  final int typeId = 1;

  @override
  PdfModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfModel(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      folderId: fields[3] as String,
      timeAdded: fields[4] as DateTime,
      lastReadPage: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PdfModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.folderId)
      ..writeByte(4)
      ..write(obj.timeAdded)
      ..writeByte(5)
      ..write(obj.lastReadPage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
