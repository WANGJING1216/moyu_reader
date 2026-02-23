import '../entities/imported_text_book.dart';

abstract class BookImportRepository {
  Future<ImportedTextBook?> pickAndImportTxt();
}
