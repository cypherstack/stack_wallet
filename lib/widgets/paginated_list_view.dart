import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../themes/stack_colors.dart';
import '../utilities/assets.dart';
import '../utilities/text_styles.dart';
import 'custom_buttons/app_bar_icon_button.dart';

enum PageItemPosition { first, last, solo, somewhere }

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, PageItemPosition position)
  itemBuilder;
  final int itemsPerPage;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 50,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  int _currentPage = 0;
  late int _totalPages;
  late List<T> _currentPageItems;

  void _updatePagination() {
    _totalPages = (widget.items.length / widget.itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    if (_currentPage >= _totalPages) {
      _currentPage = _totalPages - 1;
    }

    _updateCurrentPageItems();
  }

  void _updateCurrentPageItems() {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(
      0,
      widget.items.length,
    );
    _currentPageItems = widget.items.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (mounted && page >= 0 && page < _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
        _updateCurrentPageItems();
      });
    }
  }

  void _nextPage() => _goToPage(_currentPage + 1);
  void _previousPage() => _goToPage(_currentPage - 1);
  void _firstPage() => _goToPage(0);
  void _lastPage() => _goToPage(_totalPages - 1);

  @override
  void initState() {
    super.initState();
    _updatePagination();
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.itemsPerPage != widget.itemsPerPage) {
      _updatePagination();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _currentPageItems.length,
            separatorBuilder: (context, index) {
              return Container(
                width: double.infinity,
                height: 2,
                color: Theme.of(context).extension<StackColors>()!.background,
              );
            },
            itemBuilder: (context, index) {
              final PageItemPosition position;
              if (_currentPageItems.length == 1) {
                position = .solo;
              } else if (index == _currentPageItems.length - 1) {
                position = .last;
              } else if (index == 0) {
                position = .first;
              } else {
                position = .somewhere;
              }

              return widget.itemBuilder(
                context,
                _currentPageItems[index],
                position,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          children: [
            IconButton(
              color: Theme.of(
                context,
              ).extension<StackColors>()!.topNavIconPrimary,
              disabledColor: Theme.of(
                context,
              ).extension<StackColors>()!.topNavIconPrimary.withAlpha(100),
              icon: const Icon(Icons.first_page),
              onPressed: _currentPage > 0 ? _firstPage : null,
              tooltip: "First page",
            ),
            const SizedBox(width: 8),
            AppBarIconButton(
              icon: Transform.flip(
                flipX: true,
                child: SvgPicture.asset(
                  Assets.svg.chevronRight,
                  width: 24,
                  height: 24,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary
                      .withAlpha(_currentPage > 0 ? 255 : 100),
                ),
              ),
              tooltip: "Previous page",
              onPressed: _currentPage > 0 ? _previousPage : null,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "${_currentPage + 1} / $_totalPages",
                style: STextStyles.w500_14(context).copyWith(
                  color: Theme.of(
                    context,
                  ).extension<StackColors>()!.topNavIconPrimary.withAlpha(190),
                ),
              ),
            ),

            AppBarIconButton(
              icon: SvgPicture.asset(
                Assets.svg.chevronRight,
                width: 24,
                height: 24,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .topNavIconPrimary
                    .withAlpha(_currentPage < _totalPages - 1 ? 255 : 100),
              ),
              tooltip: "Next page",
              onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              color: Theme.of(
                context,
              ).extension<StackColors>()!.topNavIconPrimary,
              disabledColor: Theme.of(
                context,
              ).extension<StackColors>()!.topNavIconPrimary.withAlpha(100),
              icon: const Icon(Icons.last_page),
              onPressed: _currentPage < _totalPages - 1 ? _lastPage : null,
              tooltip: "Last page",
            ),
          ],
        ),
      ],
    );
  }
}
