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
    // 💡 การแก้ไข: ใช้ Null-aware coalescing (??) และ Safe Casting (as type?) 
    // เพื่อให้ไม่ Crash ถ้าฟิลด์เป็น null หรือประเภทข้อมูลผิดพลาด
    
    return Movie(
      // สำหรับ String: ถ้าเป็น null หรือไม่ใช่ String ให้ใช้สตริงว่าง "" หรือค่าเริ่มต้น
      date: (json['date'] as String?) ?? 'ไม่ระบุวันที่',
      genre: (json['genre'] as String?) ?? 'ไม่ระบุประเภท',
      poster: (json['poster'] as String?) ?? '', // ใช้ String ว่าง ถ้าไม่มีรูป
      title: (json['title'] as String?) ?? 'ชื่อหนังไม่ระบุ',
      
      // สำหรับ Bool: ถ้าเป็น null หรือไม่ใช่ bool ให้ใช้ false (ค่าเริ่มต้นที่ปลอดภัย)
      isNowShowing: (json['isNowShowing'] as bool?) ?? false,
      preorder: (json['preorder'] as bool?) ?? false,
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