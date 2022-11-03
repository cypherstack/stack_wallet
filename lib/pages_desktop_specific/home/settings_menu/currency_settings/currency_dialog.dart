// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:stackwallet/providers/global/base_currencies_provider.dart';
// import 'package:stackwallet/providers/global/prefs_provider.dart';
// import 'package:stackwallet/utilities/assets.dart';
// import 'package:stackwallet/utilities/constants.dart';
// import 'package:stackwallet/utilities/text_styles.dart';
// import 'package:stackwallet/utilities/theme/stack_colors.dart';
// import 'package:stackwallet/utilities/util.dart';
// import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
// import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
// import 'package:stackwallet/widgets/desktop/primary_button.dart';
// import 'package:stackwallet/widgets/desktop/secondary_button.dart';
// import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
// import 'package:stackwallet/widgets/rounded_container.dart';
// import 'package:stackwallet/widgets/stack_text_field.dart';
// import 'package:stackwallet/widgets/textfield_icon_button.dart';
//
// class CurrencyDialog extends ConsumerStatefulWidget {
//   const CurrencyDialog({Key? key}) : super(key: key);
//
//   @override
//   ConsumerState<CurrencyDialog> createState() => _CurrencyDialog();
// }
//
// class _CurrencyDialog extends ConsumerState<CurrencyDialog> {
//   late String current;
//   late List<String> currenciesWithoutSelected;
//
//   late final TextEditingController searchCurrencyController;
//
//   late final FocusNode searchCurrencyFocusNode;
//
//   void onTap(int index) {
//     if (currenciesWithoutSelected[index] == current || current.isEmpty) {
//       // ignore if already selected currency
//       return;
//     }
//     current = currenciesWithoutSelected[index];
//     currenciesWithoutSelected.remove(current);
//     currenciesWithoutSelected.insert(0, current);
//     ref.read(prefsChangeNotifierProvider).currency = current;
//   }
//
//   BorderRadius? _borderRadius(int index) {
//     if (index == 0 && currenciesWithoutSelected.length == 1) {
//       return BorderRadius.circular(
//         Constants.size.circularBorderRadius,
//       );
//     } else if (index == 0) {
//       return BorderRadius.vertical(
//         top: Radius.circular(
//           Constants.size.circularBorderRadius,
//         ),
//       );
//     } else if (index == currenciesWithoutSelected.length - 1) {
//       return BorderRadius.vertical(
//         bottom: Radius.circular(
//           Constants.size.circularBorderRadius,
//         ),
//       );
//     }
//     return null;
//   }
//
//   String filter = "";
//
//   List<String> _filtered() {
//     final currencyMap = ref.read(baseCurrenciesProvider).map;
//     return currenciesWithoutSelected.where((element) {
//       return element.toLowerCase().contains(filter.toLowerCase()) ||
//           (currencyMap[element]?.toLowerCase().contains(filter.toLowerCase()) ??
//               false);
//     }).toList();
//   }
//
//   @override
//   void initState() {
//     searchCurrencyController = TextEditingController();
//
//     searchCurrencyFocusNode = FocusNode();
//
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     searchCurrencyController.dispose();
//
//     searchCurrencyFocusNode.dispose();
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     current = ref
//         .watch(prefsChangeNotifierProvider.select((value) => value.currency));
//
//     currenciesWithoutSelected = ref
//         .watch(baseCurrenciesProvider.select((value) => value.map))
//         .keys
//         .toList();
//     if (current.isNotEmpty) {
//       currenciesWithoutSelected.remove(current);
//       currenciesWithoutSelected.insert(0, current);
//     }
//     currenciesWithoutSelected = _filtered();
//
//     return DesktopDialog(
//       maxHeight: 800,
//       maxWidth: 600,
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Text(
//                   "Select currency",
//                   style: STextStyles.desktopH3(context),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const DesktopDialogCloseButton(),
//             ],
//           ),
//           Expanded(
//             flex: 24,
//             child: NestedScrollView(
//               floatHeaderSlivers: true,
//               headerSliverBuilder: (context, innerBoxIsScrolled) {
//                 return [
//                   SliverOverlapAbsorber(
//                     handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
//                         context),
//                     sliver: SliverToBoxAdapter(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                             vertical: 16, horizontal: 32),
//                         child: Column(
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 16),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(
//                                   Constants.size.circularBorderRadius,
//                                 ),
//                                 child: TextField(
//                                   autocorrect: Util.isDesktop ? false : true,
//                                   enableSuggestions:
//                                       Util.isDesktop ? false : true,
//                                   controller: searchCurrencyController,
//                                   focusNode: searchCurrencyFocusNode,
//                                   onChanged: (newString) {
//                                     setState(() => filter = newString);
//                                   },
//                                   style: STextStyles.field(context),
//                                   decoration: standardInputDecoration(
//                                     "Search",
//                                     searchCurrencyFocusNode,
//                                     context,
//                                   ).copyWith(
//                                     prefixIcon: Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 10,
//                                         vertical: 16,
//                                       ),
//                                       child: SvgPicture.asset(
//                                         Assets.svg.search,
//                                         width: 16,
//                                         height: 16,
//                                       ),
//                                     ),
//                                     suffixIcon: searchCurrencyController
//                                             .text.isNotEmpty
//                                         ? Padding(
//                                             padding:
//                                                 const EdgeInsets.only(right: 0),
//                                             child: UnconstrainedBox(
//                                               child: Row(
//                                                 children: [
//                                                   TextFieldIconButton(
//                                                     child: const XIcon(),
//                                                     onTap: () async {
//                                                       setState(() {
//                                                         searchCurrencyController
//                                                             .text = "";
//                                                         filter = "";
//                                                       });
//                                                     },
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           )
//                                         : null,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ];
//               },
//               body: Builder(
//                 builder: (context) {
//                   return CustomScrollView(
//                     slivers: [
//                       SliverOverlapInjector(
//                         handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
//                           context,
//                         ),
//                       ),
//                       SliverList(
//                         delegate: SliverChildBuilderDelegate(
//                           (context, index) {
//                             return Container(
//                               decoration: BoxDecoration(
//                                 color: Theme.of(context)
//                                     .extension<StackColors>()!
//                                     .popupBG,
//                                 borderRadius: _borderRadius(index),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(4),
//                                 key: Key(
//                                     "desktopSettingsCurrencySelect_${currenciesWithoutSelected[index]}"),
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 32),
//                                   child: RoundedContainer(
//                                     padding: const EdgeInsets.all(0),
//                                     color: currenciesWithoutSelected[index] ==
//                                             current
//                                         ? Theme.of(context)
//                                             .extension<StackColors>()!
//                                             .currencyListItemBG
//                                         : Theme.of(context)
//                                             .extension<StackColors>()!
//                                             .popupBG,
//                                     child: RawMaterialButton(
//                                       onPressed: () async {
//                                         onTap(index);
//                                       },
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(
//                                           Constants.size.circularBorderRadius,
//                                         ),
//                                       ),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(12.0),
//                                         child: Row(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               child: Radio(
//                                                 activeColor: Theme.of(context)
//                                                     .extension<StackColors>()!
//                                                     .radioButtonIconEnabled,
//                                                 materialTapTargetSize:
//                                                     MaterialTapTargetSize
//                                                         .shrinkWrap,
//                                                 value: true,
//                                                 groupValue:
//                                                     currenciesWithoutSelected[
//                                                             index] ==
//                                                         current,
//                                                 onChanged: (_) {
//                                                   onTap(index);
//                                                 },
//                                               ),
//                                             ),
//                                             const SizedBox(
//                                               width: 12,
//                                             ),
//                                             Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   currenciesWithoutSelected[
//                                                       index],
//                                                   key: (currenciesWithoutSelected[
//                                                               index] ==
//                                                           current)
//                                                       ? const Key(
//                                                           "desktopSettingsSelectedCurrencyText")
//                                                       : null,
//                                                   style:
//                                                       STextStyles.largeMedium14(
//                                                           context),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 2,
//                                                 ),
//                                                 Text(
//                                                   ref.watch(baseCurrenciesProvider
//                                                               .select((value) =>
//                                                                   value.map))[
//                                                           currenciesWithoutSelected[
//                                                               index]] ??
//                                                       "",
//                                                   key: (currenciesWithoutSelected[
//                                                               index] ==
//                                                           current)
//                                                       ? const Key(
//                                                           "desktopSelectedCurrencyTextDescription")
//                                                       : null,
//                                                   style:
//                                                       STextStyles.itemSubtitle(
//                                                           context),
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                           childCount: currenciesWithoutSelected.length,
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(32),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: SecondaryButton(
//                     label: "Cancel",
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ),
//                 const SizedBox(
//                   width: 16,
//                 ),
//                 Expanded(
//                   child: PrimaryButton(
//                     label: "Save Changes",
//                     onPressed: () {},
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
