class NewsItem {
  final String link;
  final String title;
  final String mediaUrl;

  NewsItem({
    required this.link,
    required this.title,
    required this.mediaUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      link: json["link"] ?? "",
      title: json["title"] ?? "",
      mediaUrl: json["image_url"] ?? "",
    );
  }
}
