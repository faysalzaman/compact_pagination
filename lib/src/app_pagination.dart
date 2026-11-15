import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Builds the summary shown below the pagination controls.
///
/// Use this callback to localize the summary or adjust its wording. The
/// [startItem] and [endItem] values are both `0` when there are no items.
typedef PaginationItemsInfoBuilder = String Function({
  required int startItem,
  required int endItem,
  required int totalItems,
  required String itemLabel,
});

/// A compact, theme-aware pagination control for numbered pages.
///
/// The widget does not load or store data. It reports page and page-size
/// changes through callbacks, so it can be used with any state-management or
/// data-fetching approach.
class AppPagination extends StatelessWidget {
  /// Creates a compact pagination control.
  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.rowsPerPageOptions = const [10, 20, 50, 100],
    this.maxVisiblePages = 5,
    this.itemLabel = 'items',
    this.previousPageTooltip = 'Previous page',
    this.nextPageTooltip = 'Next page',
    this.rowsPerPageTooltip = 'Rows per page',
    this.perPageLabel = '/ page',
    this.pageLabelBuilder,
    this.itemsInfoBuilder,
    this.showItemsInfo = true,
    this.showRowsPerPage = true,
    this.showTopBorder = true,
    this.padding = const EdgeInsets.only(top: 8),
  })  : assert(currentPage >= 1),
        assert(totalPages >= 0),
        assert(totalItems >= 0),
        assert(rowsPerPage > 0),
        assert(maxVisiblePages >= 3);

  /// Current active page, starting at `1`.
  final int currentPage;

  /// Total number of pages. Use `0` when there are no pages.
  final int totalPages;

  /// Total number of items across all pages.
  final int totalItems;

  /// Number of items displayed per page.
  final int rowsPerPage;

  /// Called when a different page is selected.
  final ValueChanged<int> onPageChanged;

  /// Called when a different page size is selected.
  final ValueChanged<int> onRowsPerPageChanged;

  /// Available page-size options.
  final List<int> rowsPerPageOptions;

  /// Maximum number of page-number buttons to display, including first and
  /// last pages. Ellipses are not counted.
  ///
  /// This value must be at least `3` so the first, current, and last pages can
  /// be represented when there are many pages.
  final int maxVisiblePages;

  /// Noun displayed in the items summary, for example `members` or `tickets`.
  final String itemLabel;

  /// Tooltip for the previous-page button.
  final String previousPageTooltip;

  /// Tooltip for the next-page button.
  final String nextPageTooltip;

  /// Tooltip for the page-size selector.
  final String rowsPerPageTooltip;

  /// Text shown after the page size, such as `/ page` or `per page`.
  final String perPageLabel;

  /// Optional builder for localizing the accessible label for a page button.
  final String Function(int page)? pageLabelBuilder;

  /// Optional builder for localizing or customizing the items summary.
  final PaginationItemsInfoBuilder? itemsInfoBuilder;

  /// Whether to show the items summary below the controls.
  final bool showItemsInfo;

  /// Whether to show the page-size selector.
  final bool showRowsPerPage;

  /// Whether to draw a divider above the pagination control.
  final bool showTopBorder;

  /// Padding around the pagination control.
  final EdgeInsetsGeometry padding;

  static const double _buttonSize = 30;
  static const double _iconSize = 16;

  int get _safeCurrentPage {
    if (totalPages == 0) return 0;
    return currentPage.clamp(1, totalPages).toInt();
  }

  int get _startItem {
    if (totalItems == 0 || _safeCurrentPage == 0) return 0;
    return ((_safeCurrentPage - 1) * rowsPerPage + 1)
        .clamp(1, totalItems)
        .toInt();
  }

  int get _endItem {
    if (totalItems == 0 || _safeCurrentPage == 0) return 0;
    return (_safeCurrentPage * rowsPerPage).clamp(0, totalItems).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final pageNumbers = _visiblePages();

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: showTopBorder
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavigationButton(
                  context,
                  icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
                  tooltip: previousPageTooltip,
                  enabled: _safeCurrentPage > 1,
                  onPressed: () => onPageChanged(_safeCurrentPage - 1),
                ),
                const SizedBox(width: 4),
                for (var index = 0; index < pageNumbers.length; index++) ...[
                  if (index > 0 &&
                      pageNumbers[index] - pageNumbers[index - 1] > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '…',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  _buildPageButton(context, pageNumbers[index]),
                ],
                const SizedBox(width: 4),
                _buildNavigationButton(
                  context,
                  icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
                  tooltip: nextPageTooltip,
                  enabled:
                      _safeCurrentPage > 0 && _safeCurrentPage < totalPages,
                  onPressed: () => onPageChanged(_safeCurrentPage + 1),
                ),
                if (showRowsPerPage && rowsPerPageOptions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildRowsPerPageSelector(context),
                ],
              ],
            ),
          ),
          if (showItemsInfo) ...[
            const SizedBox(height: 4),
            Text(
              _buildItemsInfo(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<int> _visiblePages() {
    if (totalPages == 0) return const [];
    if (totalPages <= maxVisiblePages) {
      return List.generate(totalPages, (index) => index + 1);
    }

    final innerPageCount = math.min(maxVisiblePages - 2, totalPages - 2);
    final lastInnerPage = totalPages - 1;
    final proposedStart = _safeCurrentPage - ((innerPageCount - 1) ~/ 2);
    final firstInnerPage =
        proposedStart.clamp(2, lastInnerPage - innerPageCount + 1).toInt();
    final pages = <int>[1];

    for (var page = firstInnerPage;
        page < firstInnerPage + innerPageCount;
        page++) {
      pages.add(page);
    }

    pages.add(totalPages);
    return pages;
  }

  Widget _buildPageButton(BuildContext context, int page) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = page == _safeCurrentPage;

    return Semantics(
      button: true,
      selected: isSelected,
      label: pageLabelBuilder?.call(page) ?? 'Page $page',
      child: SizedBox(
        height: _buttonSize,
        child: TextButton(
          onPressed: isSelected ? null : () => onPageChanged(page),
          style: TextButton.styleFrom(
            minimumSize: const Size(_buttonSize, _buttonSize),
            maximumSize: const Size(double.infinity, _buttonSize),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withValues(alpha: 0.7),
            disabledForegroundColor: colorScheme.onPrimary,
            backgroundColor:
                isSelected ? colorScheme.primary : Colors.transparent,
            side: BorderSide(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            '$page',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        icon: Icon(icon),
        iconSize: _iconSize,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(
          width: _buttonSize,
          height: _buttonSize,
        ),
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.35),
          backgroundColor: colorScheme.surfaceContainerHighest,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildRowsPerPageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<int>(
      tooltip: rowsPerPageTooltip,
      initialValue: rowsPerPage,
      onSelected: onRowsPerPageChanged,
      color: colorScheme.surface,
      itemBuilder: (context) => rowsPerPageOptions
          .map(
            (size) => PopupMenuItem<int>(
              value: size,
              child: Text('$size $perPageLabel'),
            ),
          )
          .toList(growable: false),
      child: Container(
        height: _buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rowsPerPage',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: _iconSize,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }

  String _buildItemsInfo() {
    final builder = itemsInfoBuilder;
    if (builder != null) {
      return builder(
        startItem: _startItem,
        endItem: _endItem,
        totalItems: totalItems,
        itemLabel: itemLabel,
      );
    }

    return '$_startItem–$_endItem of $totalItems $itemLabel';
  }
}
