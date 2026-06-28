// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_template_model.dart';

TransactionTemplateModelAdapter _transactionTemplateModelAdapter() =>
    TransactionTemplateModelAdapter();

class TransactionTemplateModelAdapter
    extends TypeAdapter<TransactionTemplateModel> {
  @override
  final int typeId = AppConstants.typeIdTemplate;

  @override
  TransactionTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionTemplateModel(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      kind: fields[3] as String,
      categoryId: fields[4] as String,
      note: fields[5] as String,
      sortOrder: fields[6] as int,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionTemplateModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.kind)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
