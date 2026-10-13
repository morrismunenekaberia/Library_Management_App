import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/book.dart';
import '../controllers/books_controller.dart';

import '../../../../core/widgets/widgets.dart';

/// Screen displaying detailed view of a selected book with librarian edit/delete options.
class BookDetailScreen extends StatefulWidget {
  final int bookId;
  final Book? initialBook;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.initialBook,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksController>().fetchBookDetails(widget.bookId);
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text(
          'Are you sure you want to delete this book? This action cannot be undone. '
          'Books with active loans cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final success =
        await context.read<BooksController>().deleteBook(widget.bookId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Book deleted successfully')),
      );
      context.pop();
    } else {
      final error = context.read<BooksController>().errorMessage ??
          'Failed to delete book';
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final isLibrarian = authController.user?.isLibrarian ?? false;
    final booksController = context.watch<BooksController>();

    final book = booksController.selectedBook?.id == widget.bookId
        ? booksController.selectedBook
        : widget.initialBook;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          if (isLibrarian && book != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Book',
              onPressed: () {
                context.push('/books/${book.id}/edit', extra: book);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Book',
              color: theme.colorScheme.error,
              onPressed: booksController.isDeleting
                  ? null
                  : _confirmDelete,
            ),
          ],
        ],
      ),
      body: booksController.isDetailLoading && book == null
          ? const LoadingIndicator(message: 'Loading book details...')
          : book == null
              ? (booksController.errorMessage != null
                  ? ErrorState(
                      title: 'Failed to load book',
                      message: booksController.errorMessage!,
                      onRetry: () => context
                          .read<BooksController>()
                          .fetchBookDetails(widget.bookId),
                    )
                  : EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Book not found',
                      message: 'The requested book could not be found.',
                      actionLabel: 'Back to Catalogue',
                      onAction: () => context.pop(),
                    ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        book.title,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'By ${book.author}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    icon: Icons.qr_code_rounded,
                                    label: 'ISBN',
                                    value: book.isbn,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    icon: Icons.category_rounded,
                                    label: 'Category',
                                    value: book.category ?? 'Uncategorized',
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    icon: Icons.library_books_rounded,
                                    label: 'Total Copies',
                                    value: '${book.totalCopies}',
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: 'Available Copies',
                                    value: '${book.availableCopies}',
                                    valueColor: book.isAvailable
                                        ? Colors.green.shade700
                                        : theme.colorScheme.error,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Librarian quick actions at bottom
                          if (isLibrarian) ...[
                            FilledButton.icon(
                              onPressed: () {
                                context.push('/books/${book.id}/edit', extra: book);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit Book Information'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(color: theme.colorScheme.error),
                              ),
                              onPressed: booksController.isDeleting
                                  ? null
                                  : _confirmDelete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete Book'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
