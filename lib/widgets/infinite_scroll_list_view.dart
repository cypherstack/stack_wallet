import "package:flutter/widgets.dart";

/// A page of results returned from [InfiniteScrollListView.fetchPage].
///
/// Set [nextPageKey] to null to signal that this is the last page.
class InfiniteScrollPage<T, K> {
  InfiniteScrollPage({required this.items, required this.nextPageKey});

  final List<T> items;
  final K? nextPageKey;
}

/// Triggers refresh and retry on an [InfiniteScrollListView] from outside.
///
/// Create one in the parent's state, pass it to
/// [InfiniteScrollListView.controller], and call [refresh] when search/filter
/// state changes. In-flight fetches from before the refresh are discarded
/// when they complete.
class InfiniteScrollListController {
  VoidCallback? _onRefresh;
  VoidCallback? _onRetry;

  void _attach({
    required VoidCallback onRefresh,
    required VoidCallback onRetry,
  }) {
    _onRefresh = onRefresh;
    _onRetry = onRetry;
  }

  void _detach() {
    _onRefresh = null;
    _onRetry = null;
  }

  /// Discard current items and reload from the first page.
  void refresh() => _onRefresh?.call();

  /// Retry the last failed fetch.
  void retry() => _onRetry?.call();
}

/// The load lifecycle of an [InfiniteScrollListView]. A sealed type so all
/// transitions are explicit and the compiler enforces exhaustive handling.
sealed class _Status<K> {
  const _Status();
}

class _LoadingFirstPageStatus<K> extends _Status<K> {
  const _LoadingFirstPageStatus();
}

class _LoadingMoreStatus<K> extends _Status<K> {
  const _LoadingMoreStatus();
}

class _IdleStatus<K> extends _Status<K> {
  const _IdleStatus({required this.nextPageKey});

  /// Null means there are no more pages.
  final K? nextPageKey;
}

class _FailedFirstPageStatus<K> extends _Status<K> {
  const _FailedFirstPageStatus({required this.error, required this.pageKey});
  final Object error;
  final K pageKey;
}

class _FailedMoreStatus<K> extends _Status<K> {
  const _FailedMoreStatus({required this.error, required this.pageKey});
  final Object error;
  final K pageKey;
}

/// A generic infinite-scroll [ListView].
///
/// Works correctly with [shrinkWrap] as long as the parent provides bounded
/// height (e.g. inside a [Flexible] or sized container).
///
/// Search/filter changes should be applied by updating any state your
/// [fetchPage] closure reads, then calling
/// [InfiniteScrollListController.refresh].
class InfiniteScrollListView<T, K> extends StatefulWidget {
  const InfiniteScrollListView({
    super.key,
    required this.firstPageKey,
    required this.fetchPage,
    required this.itemBuilder,
    this.controller,
    this.separatorBuilder,
    this.firstPageProgressBuilder,
    this.newPageProgressBuilder,
    this.firstPageErrorBuilder,
    this.newPageErrorBuilder,
    this.emptyBuilder,
    this.noMoreItemsBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.prefetchThreshold = 200,
  });

  /// Key passed to [fetchPage] for the very first page.
  final K firstPageKey;

  /// Fetches a page. Return an [InfiniteScrollPage] with
  /// [InfiniteScrollPage.nextPageKey] set to null on the last page.
  final Future<InfiniteScrollPage<T, K>> Function(K pageKey) fetchPage;

  /// Builds a single data item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  final InfiniteScrollListController? controller;

  /// Optional separator builder. Called between data items only (not around
  /// the footer).
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  final WidgetBuilder? firstPageProgressBuilder;
  final WidgetBuilder? newPageProgressBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  firstPageErrorBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  newPageErrorBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? noMoreItemsBuilder;

  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Pixels from the bottom at which the next page begins fetching.
  final double prefetchThreshold;

  @override
  State<InfiniteScrollListView<T, K>> createState() =>
      _InfiniteScrollListViewState<T, K>();
}

class _InfiniteScrollListViewState<T, K>
    extends State<InfiniteScrollListView<T, K>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];

  _Status<K> _status = _LoadingFirstPageStatus<K>();

  /// Incremented on every refresh. Each fetch captures the value at its start;
  /// if the captured value differs from the current value when the fetch
  /// completes, the result is discarded.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller?._attach(onRefresh: _refresh, onRetry: _retry);
    // Status defaults to _LoadingFirstPage so _runFetch can be called directly.
    _runFetch(widget.firstPageKey);
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollListView<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(onRefresh: _refresh, onRetry: _retry);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Transition status to a loading variant and start a fetch.
  void _fetch(K pageKey) {
    setState(() {
      _status = _items.isEmpty
          ? _LoadingFirstPageStatus<K>()
          : _LoadingMoreStatus<K>();
    });
    _runFetch(pageKey);
  }

  /// Run a fetch without changing status. Used for the initial fetch and
  /// when auto-continuing past an empty page (status is already loading).
  Future<void> _runFetch(K pageKey) async {
    final generation = _generation;
    final wasFirstPage = _items.isEmpty;

    try {
      final result = await widget.fetchPage(pageKey);
      if (!mounted || generation != _generation) return;

      // Empty page but more pages remain: continue immediately, staying in
      // the loading state. (A buggy backend returning unbounded empty pages
      // will hammer the API here.)
      if (result.items.isEmpty && result.nextPageKey != null) {
        return _runFetch(result.nextPageKey as K);
      }

      setState(() {
        _items.addAll(result.items);
        _status = _IdleStatus<K>(nextPageKey: result.nextPageKey);
      });

      // First page may not fill the viewport. After layout, if the list
      // still isn't scrollable and more pages exist, fetch the next.
      _maybeFetchIfUnderfilled();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = wasFirstPage
            ? _FailedFirstPageStatus<K>(error: error, pageKey: pageKey)
            : _FailedMoreStatus<K>(error: error, pageKey: pageKey);
      });
    }
  }

  void _maybeFetchIfUnderfilled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_status case _IdleStatus<K>(nextPageKey: final next?)
          when _scrollController.hasClients &&
              _scrollController.position.maxScrollExtent <= 0) {
        _fetch(next);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_status case _IdleStatus<K>(nextPageKey: final next?)) {
      final position = _scrollController.position;
      if (position.pixels >=
          position.maxScrollExtent - widget.prefetchThreshold) {
        _fetch(next);
      }
    }
  }

  void _refresh() {
    _generation++;
    setState(() {
      _items.clear();
      _status = _LoadingFirstPageStatus<K>();
    });
    _runFetch(widget.firstPageKey);
  }

  void _retry() {
    if (_status
        case _FailedFirstPageStatus<K>(:final pageKey) ||
            _FailedMoreStatus<K>(:final pageKey)) {
      _fetch(pageKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return switch (_status) {
        _LoadingFirstPageStatus<K>() =>
          widget.firstPageProgressBuilder?.call(context) ??
              const _DefaultFirstPageProgress(),
        _FailedFirstPageStatus<K>(:final error) =>
          widget.firstPageErrorBuilder?.call(context, error, _retry) ??
              _DefaultErrorView(error: error, onRetry: _retry),
        _IdleStatus<K>() =>
          widget.emptyBuilder?.call(context) ?? const _DefaultEmpty(),
        // Defensive: these variants cannot occur with no items.
        _LoadingMoreStatus<K>() ||
        _FailedMoreStatus<K>() => const SizedBox.shrink(),
      };
    }

    final Widget? footer = switch (_status) {
      _LoadingMoreStatus<K>() =>
        widget.newPageProgressBuilder?.call(context) ??
            const _DefaultNewPageProgress(),
      _FailedMoreStatus<K>(:final error) =>
        widget.newPageErrorBuilder?.call(context, error, _retry) ??
            _DefaultErrorView(error: error, onRetry: _retry),
      _IdleStatus<K>(nextPageKey: null) => widget.noMoreItemsBuilder?.call(
        context,
      ),
      _IdleStatus<K>() =>
        widget.newPageProgressBuilder?.call(context) ??
            const _DefaultNewPageProgress(),
      // Defensive: these variants cannot occur with items present.
      _LoadingFirstPageStatus<K>() || _FailedFirstPageStatus<K>() => null,
    };

    final itemCount = _items.length + (footer != null ? 1 : 0);

    return NotificationListener(
      onNotification: (_) {
        _maybeFetchIfUnderfilled();
        return false;
      },
      child: ListView.separated(
        controller: _scrollController,
        primary: false,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: widget.padding,
        itemCount: itemCount,
        separatorBuilder: (context, index) {
          if (index == _items.length - 1 && footer != null) {
            return const SizedBox.shrink();
          }
          return widget.separatorBuilder?.call(context, index) ??
              const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          }
          return footer!;
        },
      ),
    );
  }
}

class _DefaultFirstPageProgress extends StatelessWidget {
  const _DefaultFirstPageProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(padding: EdgeInsets.all(24), child: Text("Loading...")),
    );
  }
}

class _DefaultNewPageProgress extends StatelessWidget {
  const _DefaultNewPageProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("Loading more..."),
      ),
    );
  }
}

class _DefaultEmpty extends StatelessWidget {
  const _DefaultEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(padding: EdgeInsets.all(24), child: Text("No items")),
    );
  }
}

class _DefaultErrorView extends StatelessWidget {
  const _DefaultErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$error"),
            const SizedBox(height: 8),
            GestureDetector(onTap: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
