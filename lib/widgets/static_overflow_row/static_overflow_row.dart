import 'package:flutter/material.dart';

import 'measure_size.dart';

class StaticOverflowRow extends StatefulWidget {
  final List<Widget> children;
  final Widget Function(int hiddenCount) overflowBuilder;

  const StaticOverflowRow({
    super.key,
    required this.children,
    required this.overflowBuilder,
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
            children: [
              ...List.generate(childCount, (i) {
                return MeasureSize(
                  onChange: (size) => _itemSizes[i] = size,
                  child: KeyedSubtree(
                    key: ValueKey("item-$i"),
                    child: widget.children[i],
                  ),
                );
              }),
              MeasureSize(
                onChange: (size) => _overflowSize = size,
                child: KeyedSubtree(
                  key: const ValueKey("overflow"),
                  child: widget.overflowBuilder(0),
                ),
              ),
            ],
          );
        }

        final List<Widget> visible = [];
        double usedWidth = 0;

        // Try first pass without overflow
        for (int i = 0; i < childCount; i++) {
          final itemSize = _itemSizes[i]!;
          if (usedWidth + itemSize.width <= constraints.maxWidth) {
            visible.add(widget.children[i]);
            usedWidth += itemSize.width;
          } else {
            // Not all children fit. Overflow required
            visible.clear();
            usedWidth = 0;
            int overflowCount = 0;

            for (int j = 0; j < childCount; j++) {
              final size = _itemSizes[j]!;
              final needsOverflow = j < childCount - 1;
              final canFit =
                  usedWidth +
                      size.width +
                      (needsOverflow ? _overflowSize!.width : 0) <=
                  constraints.maxWidth;

              if (canFit) {
                visible.add(widget.children[j]);

                usedWidth += size.width;
              } else {
                overflowCount = childCount - j;
                break;
              }
            }

            // Add overflow
            visible.add(widget.overflowBuilder(overflowCount));
            break;
          }
        }

        return Row(children: visible);
      },
    );
  }
}
