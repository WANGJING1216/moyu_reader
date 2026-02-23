import 'package:flutter/material.dart';

import '../features/bookshelf/presentation/pages/bookshelf_page.dart';
import '../features/catalog/presentation/pages/catalog_page.dart';
import '../features/import_book/application/use_cases/import_txt_book_use_case.dart';
import '../features/import_book/data/repositories/local_txt_book_import_repository.dart';
import '../features/import_book/domain/entities/imported_text_book.dart';
import '../features/import_book/presentation/pages/import_book_page.dart';
import '../features/reader/presentation/pages/reader_page.dart';

class AppRoutes {
  static const String reader = '/reader';
  static const String catalog = '/catalog';
  static const String bookshelf = '/bookshelf';
  static const String importBook = '/import-book';
}

class AppRouter {
  static const Duration catalogTransitionDuration = Duration(milliseconds: 220);

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.reader:
        return MaterialPageRoute<void>(
          builder: (_) => const ReaderPage(),
          settings: settings,
        );
      case AppRoutes.catalog:
        final Object? routeArgs = settings.arguments;
        if (routeArgs is! CatalogPageArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => const ReaderPage(),
            settings: settings,
          );
        }
        return PageRouteBuilder<int?>(
          settings: settings,
          transitionDuration: catalogTransitionDuration,
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (_, animation, secondaryAnimation) =>
              CatalogPage(args: routeArgs),
          transitionsBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                final Animation<Offset> slideAnimation =
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                return SlideTransition(position: slideAnimation, child: child);
              },
        );
      case AppRoutes.bookshelf:
        return MaterialPageRoute<void>(
          builder: (_) => const BookshelfPage(),
          settings: settings,
        );
      case AppRoutes.importBook:
        return MaterialPageRoute<ImportedTextBook?>(
          builder: (_) => const ImportBookPage(
            useCase: ImportTxtBookUseCase(
              repository: LocalTxtBookImportRepository(),
            ),
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const ReaderPage(),
          settings: settings,
        );
    }
  }
}
