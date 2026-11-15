import 'package:compact_pagination/compact_pagination.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const PaginationExampleApp());
}

class PaginationExampleApp extends StatelessWidget {
  const PaginationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagination example',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF087A4B)),
      home: const PaginationExampleScreen(),
    );
  }
}

class PaginationExampleScreen extends StatefulWidget {
  const PaginationExampleScreen({super.key});

  @override
  State<PaginationExampleScreen> createState() =>
      _PaginationExampleScreenState();
}

class _PaginationExampleScreenState extends State<PaginationExampleScreen> {
  static const _items = 97;

  var _currentPage = 1;
  var _rowsPerPage = 10;

  int get _totalPages => (_items / _rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final firstItem = (_currentPage - 1) * _rowsPerPage;
    final lastItem = (_currentPage * _rowsPerPage).clamp(0, _items).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Pagination example')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lastItem - firstItem,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final itemNumber = firstItem + index + 1;
                return ListTile(
                  leading: CircleAvatar(child: Text('$itemNumber')),
                  title: Text('Item $itemNumber'),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
          AppPagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _items,
            rowsPerPage: _rowsPerPage,
            rowsPerPageOptions: const [10, 20, 50],
            itemLabel: 'records',
            onPageChanged: (page) => setState(() => _currentPage = page),
            onRowsPerPageChanged: (size) {
              setState(() {
                _rowsPerPage = size;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
