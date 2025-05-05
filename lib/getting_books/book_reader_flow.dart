import 'dart:async';

import 'package:bookstore/getting_books/books_provider.dart';
import 'package:bookstore/services/download_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:provider/provider.dart';
import 'dart:io';
import 'package:bookstore/getting_books/data_models.dart';
import 'package:hive/hive.dart';

class PdfReader extends StatefulWidget {
  final Book book;

  const PdfReader({
    super.key,
    required this.book,
  });

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> with WidgetsBindingObserver {
  PDFViewController? _pdfViewController;
  String? _localPath;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  late BookProvider _provider;
  final _debouncer = _Debouncer(milliseconds: 500);
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.book.currentPage;
    _initializePdf();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<BookProvider>(context, listen: false);
  }

  Future<void> _initializePdf() async {
    try {
      // First try to get the local PDF path
      final pdfsBox = await Hive.openBox<String>('downloadedPdfs');
      final localPdfPath = pdfsBox.get(widget.book.id.toString());

      if (localPdfPath != null && File(localPdfPath).existsSync()) {
        // Use the local PDF file
        if (mounted) {
          setState(() {
            _localPath = localPdfPath;
            _isLoading = false;
          });
        }
        return;
      }

      // If no local file, try to download if we have a URL and internet
      final pdfUrl = widget.book.pdfUrl;
      if (pdfUrl == null) throw Exception('No PDF available');

      // Use temporary download service
      final downloadService = DownloadService();
      final tempPath =
          await downloadService.downloadTemporaryPdf(pdfUrl, widget.book.id);

      if (tempPath != null) {
        if (mounted) {
          setState(() {
            _localPath = tempPath;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load PDF: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProgress() async {
    if (!mounted) return;

    try {
      // Check if we're reading a downloaded book
      final downloadService = DownloadService();
      final isDownloaded =
          await downloadService.isBookDownloaded(widget.book.id);

      // Calculate progress percentage
      final progressPercent =
          ((_currentPage / widget.book.pageCount) * 100).clamp(0.0, 100.0);

      // Create updated book with new progress
      final updatedBook = widget.book.copyWith(
        currentPage: _currentPage,
        readProgress: progressPercent,
        lastReadAt: DateTime.now(),
      );

      // Always update in Hive if the book is downloaded
      if (isDownloaded) {
        try {
          print(
              'Debug: Updating offline progress for book ${widget.book.id} to $_currentPage page (${progressPercent.toStringAsFixed(1)}%)');
          await downloadService.updateBookProgress(updatedBook);
        } catch (e) {
          print('Error updating offline progress: $e');
          if (mounted) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to save offline progress: ${e.toString()}')),
            );
          }
        }
      }

      // Try to update backend and provider if online
      try {
        await _provider.updateReadingProgress(
          bookId: widget.book.id,
          currentPage: _currentPage,
        );
      } catch (e) {
        print('Error updating online progress: $e');
        // If we're offline, this is expected to fail, so only show error if book isn't downloaded
        if (!isDownloaded && mounted) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to save online progress: ${e.toString()}')),
          );
        }
      }
    } catch (e) {
      print('Error in _updateProgress: $e');
      if (mounted) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Failed to save progress: ${e.toString()}')),
        );
      }
    }
  }

  void _handlePageChange(int page) {
    if (!mounted) return;
    setState(() => _currentPage = page);
    _debouncer.run(_updateProgress);
  }

  @override
  void dispose() {
    // Ensure progress is saved when reader is closed
    _updateProgressEverywhere();

    // Clean up temporary PDFs when reader is closed
    DownloadService().cleanupTemporaryPdfs();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _updateProgressEverywhere();
    }
  }

  Future<void> _updateProgressEverywhere() async {
    // First update progress in backend and provider
    await _updateProgress();

    // Then update in Hive if the book is downloaded
    try {
      final downloadService = DownloadService();
      if (await downloadService.isBookDownloaded(widget.book.id)) {
        // Get the updated book from provider to ensure we have latest data
        final bookProvider = Provider.of<BookProvider>(
            _navigatorKey.currentContext!,
            listen: false);
        final updatedBook = bookProvider.getBookById(widget.book.id);

        if (updatedBook != null) {
          // Update the book in Hive storage
          await downloadService.updateBookProgress(updatedBook);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to update offline progress: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 237, 241, 245),
            title: Text(
              widget.book.title,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              if (widget.book.lastReadAt != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Last read: ${_formatDateTime(widget.book.lastReadAt!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_localPath == null)
      return const Center(child: Text('No PDF available'));

    return Column(
      children: [
        Expanded(
          child: PDFView(
            filePath: _localPath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            onRender: (pages) {
              setState(() => _totalPages = pages!);
            },
            onViewCreated: (controller) {
              setState(() => _pdfViewController = controller);
            },
            onPageChanged: (page, _) => _handlePageChange(page ?? 0),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPage > 0
                    ? () {
                        _pdfViewController?.setPage(_currentPage - 1);
                      }
                    : null,
              ),
              Text('${_currentPage + 1} / $_totalPages'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        _pdfViewController?.setPage(_currentPage + 1);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _Debouncer {
  final int milliseconds;
  Timer? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
