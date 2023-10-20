import 'package:flutter/material.dart';
// import 'package:stackwallet/themes/stack_colors.dart';
// import 'package:stackwallet/utilities/text_styles.dart';
// import 'package:stackwallet/utilities/util.dart';
// import 'package:stackwallet/widgets/rounded_white_container.dart';

// class TransactionV2DetailsItem extends StatelessWidget {
//   const TransactionV2DetailsItem({
//     super.key,
//     required this.label,
//     required this.data,
//     required this.infoOrientation,
//     this.topRight,
//     this.bottomLeft,
//   });
//
//   final String label;
//   final String data;
//   final Axis infoOrientation;
//   final bool showLabelBelowData;
//
//   final Widget? topRight;
//   final Widget? bottomLeft;
//
//   @override
//   Widget build(BuildContext context) {
//     final isDesktop = Util.isDesktop;
//
//     return RoundedWhiteContainer(
//       padding: isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12),
//       child: CommonChildren(
//         buildIndex: infoOrientation == Axis.vertical ? 0 : 1,
//         builders: [
//           (children) => Column(
//                 children: children,
//               ),
//           (children) => Row(
//                 children: children,
//               ),
//         ],
//         children: [
//             Text(
//               label,
//               style: isDesktop
//                   ? STextStyles.desktopTextExtraExtraSmall(context)
//                   : STextStyles.itemSubtitle(context),
//             ),
//           const SizedBox(height: 8,),
//           SelectableText(
//             data,
//             style: isDesktop
//                 ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
//                     color: Theme.of(context).extension<StackColors>()!.textDark,
//                   )
//                 : STextStyles.itemSubtitle12(context),
//           ),
//
//         ],
//       ),
//     );
//   }
// }

class CommonChild extends StatelessWidget {
  const CommonChild({
    super.key,
    required this.builders,
    required this.buildIndex,
    required this.child,
  });

  final Widget child;
  final int buildIndex;
  final List<Widget Function(Widget)> builders;

  @override
  Widget build(BuildContext context) {
    return builders[buildIndex](child);
  }
}

class CommonChildren extends StatelessWidget {
  const CommonChildren({
    super.key,
    required this.builders,
    required this.buildIndex,
    required this.children,
  });

  final List<Widget> children;
  final int buildIndex;
  final List<Widget Function(List<Widget>)> builders;

  @override
  Widget build(BuildContext context) {
    return builders[buildIndex](children);
  }
}
