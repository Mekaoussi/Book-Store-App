// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as int,
      title: fields[1] as String,
      author: fields[2] as String,
      description: fields[3] as String,
      coverImage: fields[4] as String,
      genres: (fields[5] as List).cast<String>(),
      pageCount: fields[6] as int,
      pdfUrl: fields[7] as String?,
      epubUrl: fields[8] as String?,
      readProgress: fields[9] as double,
      currentPage: fields[10] as int,
      isFavorite: fields[11] as bool,
      isInLibrary: fields[12] as bool,
      isPaid: fields[26] as bool,
      lastReadAt: fields[13] as DateTime?,
      rating: fields[14] as double?,
      totalRating: fields[15] as double,
      isbn: fields[16] as String,
      publicationDate: fields[17] as String,
      price: fields[18] as double,
      language: fields[19] as String,
      publisher: fields[20] as String,
      ratingsCount: fields[21] as int,
      localPdfPath: fields[22] as String?,
      localEpubPath: fields[23] as String?,
      localCoverPath: fields[24] as String?,
      downloadedAt: fields[25] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.coverImage)
      ..writeByte(5)
      ..write(obj.genres)
      ..writeByte(6)
      ..write(obj.pageCount)
      ..writeByte(7)
      ..write(obj.pdfUrl)
      ..writeByte(8)
      ..write(obj.epubUrl)
      ..writeByte(9)
      ..write(obj.readProgress)
      ..writeByte(10)
      ..write(obj.currentPage)
      ..writeByte(11)
      ..write(obj.isFavorite)
      ..writeByte(12)
      ..write(obj.isInLibrary)
      ..writeByte(13)
      ..write(obj.lastReadAt)
      ..writeByte(14)
      ..write(obj.rating)
      ..writeByte(15)
      ..write(obj.totalRating)
      ..writeByte(16)
      ..write(obj.isbn)
      ..writeByte(17)
      ..write(obj.publicationDate)
      ..writeByte(18)
      ..write(obj.price)
      ..writeByte(19)
      ..write(obj.language)
      ..writeByte(20)
      ..write(obj.publisher)
      ..writeByte(21)
      ..write(obj.ratingsCount)
      ..writeByte(22)
      ..write(obj.localPdfPath)
      ..writeByte(23)
      ..write(obj.localEpubPath)
      ..writeByte(24)
      ..write(obj.localCoverPath)
      ..writeByte(25)
      ..write(obj.downloadedAt)
      ..writeByte(26)
      ..write(obj.isPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserBookInteractionAdapter extends TypeAdapter<UserBookInteraction> {
  @override
  final int typeId = 1;

  @override
  UserBookInteraction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserBookInteraction(
      bookId: fields[0] as int,
      readProgress: fields[1] as double,
      currentPage: fields[2] as int,
      isFavorite: fields[3] as bool,
      isInLibrary: fields[4] as bool,
      lastReadAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserBookInteraction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.bookId)
      ..writeByte(1)
      ..write(obj.readProgress)
      ..writeByte(2)
      ..write(obj.currentPage)
      ..writeByte(3)
      ..write(obj.isFavorite)
      ..writeByte(4)
      ..write(obj.isInLibrary)
      ..writeByte(5)
      ..write(obj.lastReadAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBookInteractionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
