import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/book.dart';
import '../controllers/books_controller.dart';

import '../../../../core/widgets/widgets.dart';

/// Screen displaying the catalogue of books with search, pull-to-refresh,
/// and role-restricted actions.
class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BooksController>();
      if (controller.books.isEmpty) {
        controller.fetchBooks();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    context.read<BooksController>().search(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<BooksController>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final isLibrarian = authController.user?.isLibrarian ?? false;
    final booksController = context.watch<BooksController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books Catalogue'),
      ),
      floatingActionButton: isLibrarian
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/books/new');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Book'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar using SearchField
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              controller: _searchController,
              hintText: 'Search by title, author, or ISBN...',
              onSubmitted: _onSearchSubmitted,
              onClear: _onClearSearch,
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  context.read<BooksController>().clearSearch();
                }
              },
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(context, booksController, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BooksController controller,
    ThemeData theme,
  ) {
    if (controller.isLoading) {
      return const LoadingIndicator(message: 'Loading books...');
    }

    if (controller.errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () => controller.fetchBooks(isRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ErrorState(
                title: 'Failed to load books',
                message: controller.errorMessage!,
                onRetry: () => controller.fetchBooks(),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.books.isEmpty) {
      final isSearching = controller.searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () => controller.fetchBooks(isRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: isSearching
                    ? Icons.search_off_rounded
                    : Icons.menu_book_outlined,
                title: isSearching ? 'No matching books' : 'No books available',
                message: isSearching
                    ? 'No books found matching "${controller.searchQuery}".'
                    : 'The library catalogue is currently empty.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchBooks(isRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: controller.books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final book = controller.books[index];
          return _BookCard(book: book);
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = book.isAvailable;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.push('/books/${book.id}', extra: book);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    book.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AvailabilityBadge(
                  available: book.availableCopies,
                  total: book.totalCopies,
                  isAvailable: isAvailable,
                ),
              ],
            ),
              const SizedBox(height: 6),
              Text(
                'By ${book.author}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (book.category != null && book.category!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.category!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'ISBN: ${book.isbn}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final int available;
  final int total;
  final bool isAvailable;

  const _AvailabilityBadge({
    required this.available,
    required this.total,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = isAvailable
        ? Colors.green.shade700
        : theme.colorScheme.error;
    final backgroundColor = isAvailable
        ? Colors.green.shade50
        : theme.colorScheme.errorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        isAvailable ? '$available / $total avail' : '0 / $total avail',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}
