import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_cinema/Moviemodel.dart'; // เพิ่มบรรทัดนี้เพื่อ import Movie model

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Movie>> getNowShowingMovies() {
    return _db
        .collection('movies')
        .where('isNowShowing', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Movie.fromJson(doc.data())).toList());
  }

  Stream<List<Movie>> getComingSoonMovies() {
    return _db
        .collection('movies')
        .where('isNowShowing', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Movie.fromJson(doc.data())).toList());
  }
}