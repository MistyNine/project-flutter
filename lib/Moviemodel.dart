class Movie {
  final String date;
  final String genre;
  final bool isNowShowing;
  final String poster;
  final bool preorder;
  final String title;

  Movie({
    required this.date,
    required this.genre,
    required this.isNowShowing,
    required this.poster,
    required this.preorder,
    required this.title,
  });

  // สร้าง factory constructor เพื่อแปลง Map<String, dynamic> เป็น Object
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      date: json['date'] as String,
      genre: json['genre'] as String,
      isNowShowing: json['isNowShowing'] as bool,
      poster: json['poster'] as String,
      preorder: json['preorder'] as bool,
      title: json['title'] as String,
    );
  }

  // สร้างเมธอด toMap เพื่อแปลง Object กลับเป็น Map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'genre': genre,
      'isNowShowing': isNowShowing,
      'poster': poster,
      'preorder': preorder,
      'title': title,
    };
  }
}