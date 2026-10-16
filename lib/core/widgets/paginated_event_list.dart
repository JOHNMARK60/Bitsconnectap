import 'package:bits_mobile_app/models/event_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays events in the order supplied by the event timeline.
class PaginatedEventList extends StatelessWidget {
  const PaginatedEventList({
    super.key,
    required this.events,
    required this.itemBuilder,
  });

  final List<EventModel> events;
  final Widget Function(EventModel event) itemBuilder;

  @override
  Widget build(BuildContext context) => PaginatedList<EventModel>(
    items: events,
    itemId: (event) => event.id,
    itemBuilder: itemBuilder,
  );
}

class PaginatedList<T> extends StatefulWidget {
  const PaginatedList({
    super.key,
    required this.items,
    required this.itemId,
    required this.itemBuilder,
    this.pageSize = 5,
  }) : assert(pageSize > 0);

  final List<T> items;
  final Object Function(T item) itemId;
  final Widget Function(T item) itemBuilder;
  final int pageSize;

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  int _page = 1;
  late List<Object> _itemIds;

  @override
  void initState() {
    super.initState();
    _itemIds = widget.items.map(widget.itemId).toList();
  }

  @override
  void didUpdateWidget(covariant PaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.items.map(widget.itemId).toList();
    if (!listEquals(_itemIds, ids) || oldWidget.pageSize != widget.pageSize) {
      _page = 1;
    }
    _itemIds = ids;
  }

  List<int?> _pageNumbers(int total) {
    if (total <= 5) return List.generate(total, (index) => index + 1);
    if (_page <= 3) return [1, 2, 3, null, total];
    if (_page >= total - 2) return [1, null, total - 2, total - 1, total];
    return [1, null, _page, null, total];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final total = (widget.items.length / widget.pageSize).ceil();
    final start = (_page - 1) * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.items.length);
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in widget.items.sublist(start, end))
          widget.itemBuilder(event),
        const Divider(height: 24),
        Text(
          'Showing ${start + 1}–$end of ${widget.items.length} events',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final numbers = _pageNumbers(total);
            final width = (constraints.maxWidth / (numbers.length + 2)).clamp(
              0.0,
              48.0,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageButton(
                  width: width,
                  label: 'Previous page',
                  onPressed: _page > 1 ? () => setState(() => _page--) : null,
                  child: const Icon(Icons.chevron_left, size: 24),
                ),
                for (final number in numbers)
                  if (number == null)
                    SizedBox(
                      width: width,
                      height: 48,
                      child: Center(
                        child: Text(
                          '…',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    _PageButton(
                      width: width,
                      label: 'Page $number',
                      selected: number == _page,
                      onPressed: () => setState(() => _page = number),
                      child: Text('$number'),
                    ),
                _PageButton(
                  width: width,
                  label: 'Next page',
                  onPressed: _page < total
                      ? () => setState(() => _page++)
                      : null,
                  child: const Icon(Icons.chevron_right, size: 24),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.width,
    required this.label,
    required this.onPressed,
    required this.child,
    this.selected = false,
  });

  final double width;
  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      selected: selected,
      child: SizedBox(
        width: width,
        height: 48,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              foregroundColor: selected
                  ? Colors.white
                  : colors.onSurfaceVariant,
              backgroundColor: selected
                  ? const Color(0xFF3297FD)
                  : onPressed == null
                  ? colors.onSurface.withValues(alpha: 0.05)
                  : Colors.transparent,
              disabledForegroundColor: colors.onSurface.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: TextStyle(
                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
