class LastActivity {
  final String bookId;
  final String tab;
  final String? sharhFile;
  final int? page;
  final int? total;

  const LastActivity({
    required this.bookId,
    required this.tab,
    this.sharhFile,
    this.page,
    this.total,
  });
}
