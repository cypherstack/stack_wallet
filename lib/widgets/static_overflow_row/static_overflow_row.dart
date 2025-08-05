import 'package:flutter/material.dart';

import 'measure_size.dart';

class StaticOverflowRow extends StatefulWidget {
  final Widget Function(int hiddenCount) overflowBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final List<Widget> children;
  final bool forcedOverflow;

  const StaticOverflowRow({
    super.key,
    required this.overflowBuilder,
    this.mainAxisAlignment = MainAxisAlignment.end,
    this.forcedOverflow = false,
    required this.children,
  });

  @override
  State<StaticOverflowRow> createState() => _StaticOverflowRowState();
}

class _StaticOverflowRowState extends State<StaticOverflowRow> {
  final Map<int, Size> _itemSizes = {};
  Size? _overflowSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final childCount = widget.children.length;

        // Still measuring
        if (_itemSizes.length < childCount || _overflowSize == null) {
          return Row(
            mainAxisAlignment: widget.mainAxisAlignment,
            children: [
              ...List.generate(childCount, (i) {
                return MeasureSize(
                  onChange: (size) {
                    if (_itemSizes[i] != size) {
                      setState(() {
                        _itemSizes[i] = size;
                      });
                    }
                  },
                  child: KeyedSubtree(
                    key: ValueKey("item-$i"),
                    child: widget.children[i],
                  ),
                );
              }),
              MeasureSize(
                onChange: (size) {
                  if (_overflowSize != size) {
                    setState(() {
                      _overflowSize = size;
                    });
                  }
                },
                child: KeyedSubtree(
                  key: const ValueKey("overflow"),
                  child: widget.overflowBuilder(0),
                ),
              ),
            ],
          );
        }

        final List<Widget> visible = [];
        double usedWidth = (widget.forcedOverflow ? _overflowSize!.width : 0);

        bool firstPassFailed = false;
        // Try first pass without overflow
        for (int i = 0; i < childCount; i++) {
          final itemSize = _itemSizes[i]!;
          if (usedWidth + itemSize.width <= constraints.maxWidth) {
            visible.add(widget.children[i]);
            usedWidth += itemSize.width;
          } else {
            // Not all children fit. Overflow required
            firstPassFailed = true;
            break;
          }
        }

        if (firstPassFailed) {
          visible.clear();
          usedWidth = 0;
          int overflowCount = 0;
          for (int i = 0; i < childCount; i++) {
            final size = _itemSizes[i]!;
            final needsOverflow = i < childCount - 1 || widget.forcedOverflow;
            final canFit =
                usedWidth +
                    size.width +
                    (needsOverflow ? _overflowSize!.width : 0) <=
                constraints.maxWidth;

            if (canFit) {
              visible.add(widget.children[i]);
              usedWidth += size.width;
            } else {
              overflowCount = childCount - i;
              break;
            }
          }

          // Add overflow
          visible.add(widget.overflowBuilder(overflowCount));
        } else {
          if (widget.forcedOverflow) {
            // Add forced overflow
            visible.add(widget.overflowBuilder(0));
          }
        }

        return Row(
          mainAxisAlignment: widget.mainAxisAlignment,
          children: visible,
        );
      },
    );
  }
}
