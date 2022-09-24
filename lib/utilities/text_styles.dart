import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class STextStyles {
  static TextStyle pageTitleH1(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      );

  static TextStyle pageTitleH2(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );

  static TextStyle navBarTitle(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      );

  static TextStyle titleBold12(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      );

  static TextStyle subtitle(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      );

  static TextStyle subtitle500(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      );

  static TextStyle subtitle600(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      );

  static TextStyle button(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.buttonTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      );

  static TextStyle largeMedium14(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      );

  static TextStyle smallMed14(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark3,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      );

  static TextStyle smallMed12(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark3,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );

  static TextStyle label(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  static TextStyle itemSubtitle(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.infoItemLabel,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );

  static TextStyle itemSubtitle12(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );

  static TextStyle fieldLabel(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.5,
      );

  static TextStyle field(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.5,
      );

  static TextStyle baseXS(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      );

  static TextStyle link(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.accentColorRed,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );

  static TextStyle link2(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );

  static TextStyle richLink(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.accentColorBlue,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  static TextStyle w600_10(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      );

  static TextStyle syncPercent(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  static TextStyle buttonSmall(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );

  static TextStyle errorSmall(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textError,
        fontWeight: FontWeight.w500,
        fontSize: 10,
      );

  static TextStyle infoSmall(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
        fontWeight: FontWeight.w500,
        fontSize: 10,
      );

// Desktop

  static TextStyle desktopH2(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 32 / 32,
      );

  static TextStyle desktopH3(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 24 / 24,
      );

  static TextStyle desktopTextMedium(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 30 / 20,
      );

  static TextStyle desktopTextMediumRegular(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w400,
        fontSize: 20,
        height: 30 / 20,
      );

  static TextStyle desktopSubtitleH2(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w400,
        fontSize: 20,
        height: 28 / 20,
      );

  static TextStyle desktopSubtitleH1(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w400,
        fontSize: 24,
        height: 33 / 24,
      );

  static TextStyle desktopButtonEnabled(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.buttonTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 26 / 20,
      );

  static TextStyle desktopButtonDisabled(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context)
            .extension<StackColors>()!
            .buttonTextPrimaryDisabled,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 26 / 20,
      );

  static TextStyle desktopButtonSecondaryEnabled(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 26 / 20,
      );

  static TextStyle desktopTextExtraSmall(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context)
            .extension<StackColors>()!
            .buttonTextPrimaryDisabled,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 24 / 16,
      );

  static TextStyle desktopButtonSmallSecondaryEnabled(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 24 / 16,
      );

  static TextStyle desktopTextFieldLabel(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textSubtitle2,
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 30 / 20,
      );

  static TextStyle desktopMenuItem(BuildContext context) => GoogleFonts.inter(
        color: Theme.of(context)
            .extension<StackColors>()!
            .textDark
            .withOpacity(0.8),
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 20.8 / 16,
      );
  static TextStyle desktopMenuItemSelected(BuildContext context) =>
      GoogleFonts.inter(
        color: Theme.of(context).extension<StackColors>()!.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 20.8 / 16,
      );
}
