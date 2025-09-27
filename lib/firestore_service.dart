import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_cinema/Moviemodel.dart'; // ตรวจสอบว่าไฟล์นี้ถูก import ถูกต้อง

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Movie>> getNowShowingMovies() {
    return _db
        .collection('movies')
        .where('isNowShowing', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final List<Movie> validMovies = [];
          
          // วนลูปผ่านทุก Document และลองแปลงข้อมูล
          for (var doc in snapshot.docs) {
            try {
              // พยายามแปลง Map<String, dynamic> เป็น Movie Model
              final movie = Movie.fromJson(doc.data());
              validMovies.add(movie);
            } catch (e) {
              // 🚨 ถ้าเกิดข้อผิดพลาดในการแปลง (เช่น ฟิลด์หายไป, ประเภทข้อมูลผิด)
              // จะพิมพ์ Error ออกมาใน Console และข้าม Document นั้นไป
              print('🔥 Error parsing movie data from Firestore (ID: ${doc.id}): $e');
            }
          }
          
          return validMovies; // คืนค่าเฉพาะรายการหนังที่ถูกต้อง
        });
  }

  Stream<List<Movie>> getComingSoonMovies() {
    return _db
        .collection('movies')
        .where('isNowShowing', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final List<Movie> validMovies = [];
          
          // วนลูปผ่านทุก Document และลองแปลงข้อมูล
          for (var doc in snapshot.docs) {
            try {
              final movie = Movie.fromJson(doc.data());
              validMovies.add(movie);
            } catch (e) {
              print('🔥 Error parsing movie data from Firestore (ID: ${doc.id}): $e');
            }
          }
          
          return validMovies;
        });
  }
}