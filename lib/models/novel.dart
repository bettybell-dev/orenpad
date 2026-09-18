class Novel {
  String title;
  String description;
  String? coverPath;
  List<String> tags;
  List<Chapter> chapters;

  Novel({
    required this.title,
    this.description = '',
    this.coverPath,
    List<String>? tags,
    List<Chapter>? chapters,
  })  : tags = tags ?? [],
        chapters = chapters ?? [];
}

class Chapter {
  String title;
  String content;
  String status;

  Chapter({
    required this.title,
    this.content = '',
    this.status = 'writing',
  });
}
