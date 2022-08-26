enum Language {
  englishUS,
  // TODO: add more
}

extension LanguageExt on Language {
  String get simple {
    switch (this) {
      case Language.englishUS:
        return "English";
    }
  }

  String get description {
    switch (this) {
      case Language.englishUS:
        return "English (US)";
    }
  }
}

Language languageFromDescription(String description) {
  switch (description) {
    case "English (US)":
      return Language.englishUS;
    default:
      throw ArgumentError("Unknown language description!");
  }
}
