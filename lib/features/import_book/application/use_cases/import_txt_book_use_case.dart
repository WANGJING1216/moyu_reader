import '../../domain/entities/imported_text_book.dart';
import '../../domain/repositories/book_import_repository.dart';

class ImportTxtBookUseCase {
  const ImportTxtBookUseCase({required BookImportRepository repository})
    : _repository = repository;

  final BookImportRepository _repository;

  Future<ImportedTextBook?> call() {
    return _repository.pickAndImportTxt();
  }
}
