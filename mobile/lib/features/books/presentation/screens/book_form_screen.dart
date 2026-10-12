import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/book.dart';
import '../controllers/books_controller.dart';

/// Form screen for adding a new book or editing an existing book.
class BookFormScreen extends StatefulWidget {
  final int? bookId;
  final Book? initialBook;

  const BookFormScreen({super.key, this.bookId, this.initialBook});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _isbnController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _totalCopiesController;

  bool get isEditing => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    final book = widget.initialBook;
    _isbnController = TextEditingController(text: book?.isbn ?? '');
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _categoryController = TextEditingController(text: book?.category ?? '');
    _totalCopiesController = TextEditingController(
      text: book != null ? '${book.totalCopies}' : '1',
    );
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _totalCopiesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<BooksController>();
    final isbn = _isbnController.text.trim();
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final category = _categoryController.text.trim();
    final totalCopies = int.parse(_totalCopiesController.text.trim());

    if (isEditing) {
      final updated = await controller.updateBook(
        widget.bookId!,
        isbn: isbn,
        title: title,
        author: author,
        category: category.isEmpty ? null : category,
        totalCopies: totalCopies,
      );

      if (mounted) {
        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book updated successfully')),
          );
          context.pop(updated);
        }
      }
    } else {
      final created = await controller.createBook(
        isbn: isbn,
        title: title,
        author: author,
        category: category.isEmpty ? null : category,
        totalCopies: totalCopies,
      );

      if (mounted) {
        if (created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book created successfully')),
          );
          context.pop(created);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booksController = context.watch<BooksController>();
    final isSaving = booksController.isSaving;
    final formError = booksController.formErrorMessage;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Book' : 'Add New Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form error banner
                  if (formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formError,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Book Title *',
                      hintText: 'e.g. Introduction to Algorithms',
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (value.trim().length > 300) {
                        return 'Title cannot exceed 300 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Author field
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author *',
                      hintText: 'e.g. Thomas H. Cormen',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Author is required';
                      }
                      if (value.trim().length > 300) {
                        return 'Author cannot exceed 300 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ISBN field
                  TextFormField(
                    controller: _isbnController,
                    decoration: const InputDecoration(
                      labelText: 'ISBN *',
                      hintText: 'e.g. 9780262033848',
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ISBN is required';
                      }
                      if (value.trim().length > 20) {
                        return 'ISBN cannot exceed 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category field
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      hintText: 'e.g. Computer Science',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value != null && value.trim().length > 100) {
                        return 'Category cannot exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Total Copies field
                  TextFormField(
                    controller: _totalCopiesController,
                    decoration: const InputDecoration(
                      labelText: 'Total Copies *',
                      hintText: 'e.g. 5',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Total copies is required';
                      }
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Total copies must be a non-negative integer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  FilledButton(
                    onPressed: isSaving ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Create Book',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
