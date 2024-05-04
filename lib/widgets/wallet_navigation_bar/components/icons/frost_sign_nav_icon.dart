/*
* This file is part of Stack Wallet.
*
* Copyright (c) 2023 Cypher Stack
* All Rights Reserved.
* The code is distributed under GPLv3 license, see LICENSE file for details.
* Generated by Cypher Stack on 2023-05-26
*
*/

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/themes/theme_providers.dart';

class FrostSignNavIcon extends ConsumerWidget {
  const FrostSignNavIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.file(
      File(
        ref.watch(
          themeProvider.select(
            // TODO: [prio=high] update themes with icon asset
            (value) => value.assets.stackIcon,
          ),
        ),
      ),
      width: 24,
      height: 24,
    );
  }
}