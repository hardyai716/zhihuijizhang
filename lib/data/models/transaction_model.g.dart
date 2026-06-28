// GENERATED CODE - DO NOT MODIFY BY HAND
// 用途：替代 build_runner 输出，便于无依赖运行
// 真实工程中由 `flutter pub run build_runner build` 自动生成

part of 'transaction_model.dart';

TransactionModelAdapter _transactionModelAdapter() =>
    TransactionModelAdapter();

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = AppConstants.typeIdTransaction;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      kind: fields[2] as String,
      categoryId: fields[3] as String,
      date: fields[4] as DateTime,
      note: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
