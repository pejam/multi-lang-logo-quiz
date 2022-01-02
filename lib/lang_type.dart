enum LangType {
   EN,
   FA,
}

extension LangTypeExtension on LangType {
  int get value {
    switch (this) {
      case LangType.EN:
        return 0;
      case LangType.FA:
        return 1;
      default:
        return 0;
    }
  }

  String get enName {
    switch (this) {
      case LangType.EN:
        return 'English';
      case LangType.FA:
        return 'Persian';
      default:
        return 'English';
    }
  }

  List<String> get listOfEnName {
    return <String>[LangType.EN.enName, LangType.FA.enName];
  }

  String get faName {
    switch (this) {
      case LangType.EN:
        return 'انگلیسی';
      case LangType.FA:
        return 'فارسی';
      default:
        return 'فارسی';
    }
  }

  List<String> get listOfFaName {
    return <String>[LangType.EN.faName, LangType.FA.faName];
  }



}
