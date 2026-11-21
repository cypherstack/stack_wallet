/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import 'package:flutter/material.dart';

import '../../utilities/constants.dart';

class SelectableUtxoSurface extends StatelessWidget {
  const SelectableUtxoSurface({
    super.key,
    required this.canSelect,
    required this.selected,
    required this.onToggle,
    required this.child,
    this.color,
  });

  final bool canSelect;
  final bool selected;
  final VoidCallback onToggle;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!canSelect) {
      return child;
    }

    return Semantics(
      selected: selected,
      child: MaterialButton(
        minWidth: 0,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        color: color,
        elevation: 0,
        disabledElevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: onToggle,
        child: child,
      ),
    );
  }
}
