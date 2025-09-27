import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
// ต้องมั่นใจว่า 2 ไฟล์นี้พร้อมใช้งาน
import 'package:movie_cinema/firestore_service.dart'; 
import 'package:movie_cinema/Moviemodel.dart'; 

// ============================
// Poster Widget Loader
// ============================
Widget _poster(String path, {BoxFit fit = BoxFit.cover}) {
  final isAsset = !path.startsWith('http');
  if (isAsset) return Image.asset(path, fit: fit);

  return CachedNetworkImage(
    imageUrl: path,
    fit: fit,
    placeholder: (_, __) => const ColoredBox(color: Color(0xFF1E1E1E)),
    errorWidget: (_, __, ___) =>
        const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
  );
}

// ====================================================================
// 🏠 HOMESCREEN - ถูกเปลี่ยนเป็น StatefulWidget เพื่อจัดการข้อมูลการค้นหา
// ====================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 💾 ตัวแปรสำหรับเก็บรายการหนังทั้งหมดเพื่อใช้ในการค้นหา
  List<Movie> _allMoviesForSearch = []; 
  bool _isSearchDataLoading = true;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchAllMoviesForSearch();
  }

  // 📡 ฟังก์ชันสำหรับดึงหนังทั้งหมด (กำลังฉาย + โปรแกรมหน้า) มาเก็บไว้ใช้ค้นหา
  Future<void> _fetchAllMoviesForSearch() async {
    try {
      // ดึงข้อมูลแบบ Single Fetch (ใช้ .first) เพื่อนำมาใช้ในการค้นหา
      final nowShowingFuture = _firestoreService.getNowShowingMovies().first; 
      final comingSoonFuture = _firestoreService.getComingSoonMovies().first; 

      final nowShowing = await nowShowingFuture;
      final comingSoon = await comingSoonFuture;

      setState(() {
        // รวมรายการหนังทั้งสองประเภทเข้าด้วยกัน
        _allMoviesForSearch = [...nowShowing, ...comingSoon];
        _isSearchDataLoading = false;
      });
    } catch (e) {
      print("Error fetching all movies for search: $e");
      setState(() {
        _isSearchDataLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ============================
      // APP BAR
      // ============================
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'M',
                style: GoogleFonts.kanit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOVIE',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'CINEMA',
                  style: GoogleFonts.kanit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ✅ ปุ่มค้นหา (ใช้ _ActionChip)
          Padding(
            padding: const EdgeInsets.only(right: 6, left: 12),
            child: _ActionChip(
              icon: _isSearchDataLoading 
                  ? Icons.hourglass_empty // แสดง Icon อื่นแทนการโหลดดิ้ง
                  : Icons.search,
              onTap: () {
                if (_isSearchDataLoading) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กำลังโหลดข้อมูลหนังสำหรับค้นหา...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (_allMoviesForSearch.isNotEmpty) {
                  showSearch(
                    context: context,
                    delegate: MovieSearchDelegate(
                      source: _allMoviesForSearch,
                    ),
                  );
                }
              },
            ),
          ),
          
          // ปุ่มโปรไฟล์ (ใช้ _ActionChip)
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 6),
            child: _ActionChip(
              icon: Icons.person,
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ),
        ],
      ),
      // ============================
      // BODY
      // ============================
      body: Column(
        children: [
          const PromoCarousel(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: const [
                NowShowingSection(),
                ComingSoonSection(),
                LatestTechSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------
// ✅ _ActionChip: ปุ่ม action เล็ก ๆ ที่มีเอฟเฟกต์ InkWell
// --------------------------------------------------------------------
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: radius,
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
      ),
    );
  }
}
// --------------------------------------------------------------------

// 🎞 PROMO CAROUSEL (สไลด์โปรโมชัน)
// --------------------------------------------------------------------
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  final _banners = const [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = (_current + 1) % _banners.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _poster(_banners[i]),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }
}
// --------------------------------------------------------------------

// 🍿 NOW SHOWING SECTION
// --------------------------------------------------------------------
class NowShowingSection extends StatelessWidget {
  const NowShowingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'กำลังฉาย',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),

        // StreamBuilder เพื่อดึงข้อมูลจาก Firestore
        StreamBuilder<List<Movie>>(
          stream: FirestoreService().getNowShowingMovies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox(
                height: 400,
                child: Center(child: Text('Error loading movies', style: TextStyle(color: Colors.white))),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 400,
                child: Center(child: Text('ไม่มีหนังกำลังฉาย', style: TextStyle(color: Colors.white70))),
              );
            }

            final items = snapshot.data!;
            return SizedBox(
              height: 400,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final m = items[i];
                  return _MovieCardHorizontal(
                    title: m.title,
                    poster: m.poster,
                    genre: m.genre,
                    dateText: m.date,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/showtimes',
                      arguments: m.toMap(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MovieCardHorizontal extends StatelessWidget {
  final String title, poster, genre, dateText;
  final VoidCallback onTap;

  const _MovieCardHorizontal({
    required this.title,
    required this.poster,
    required this.genre,
    required this.dateText,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        color: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Hero(
                  tag: 'poster_$title',
                  child: _poster(poster),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genre,
                        style: GoogleFonts.kanit(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: GoogleFonts.kanit(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>((
                              Set<WidgetState> states,
                            ) {
                              if (states.contains(WidgetState.hovered)) {
                                return const Color(0xFFE53935);
                              }
                              return Colors.redAccent;
                            }),
                            foregroundColor: WidgetStateProperty.all<Color>(
                              Colors.white,
                            ),
                            padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(vertical: 4),
                            ),
                            shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          onPressed: onTap,
                          child: const Text(
                            'เลือก',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// --------------------------------------------------------------------

// 🎬 COMING SOON SECTION (โปรแกรมหน้า)
// --------------------------------------------------------------------
class ComingSoonSection extends StatelessWidget {
  const ComingSoonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'โปรแกรมหน้า',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),

        // StreamBuilder เพื่อดึงข้อมูลจาก Firestore
        StreamBuilder<List<Movie>>(
          stream: FirestoreService().getComingSoonMovies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox(
                height: 400,
                child: Center(child: Text('Error loading movies', style: TextStyle(color: Colors.white))),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 400,
                child: Center(child: Text('ไม่มีหนังโปรแกรมหน้า', style: TextStyle(color: Colors.white70))),
              );
            }

            final items = snapshot.data!;
            return SizedBox(
              height: 400,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final m = items[i];
                  return _ComingSoonCard(
                    title: m.title,
                    poster: m.poster,
                    genre: m.genre,
                    dateText: m.date,
                    preorder: m.preorder,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/showtimes',
                      arguments: m.toMap(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// 🎬 การ์ดหนัง Coming Soon (ไม่มีปุ่มเลือก)
class _ComingSoonCard extends StatelessWidget {
  final String title, poster, genre, dateText;
  final bool preorder;
  final VoidCallback onTap;

  const _ComingSoonCard({
    required this.title,
    required this.poster,
    required this.genre,
    required this.dateText,
    required this.preorder,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        color: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Hero(tag: 'poster_$title', child: _poster(poster)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        genre,
                        style: GoogleFonts.kanit(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: GoogleFonts.kanit(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (preorder)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ซื้อตั๋วล่วงหน้า',
                            style: GoogleFonts.kanit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// --------------------------------------------------------------------

// 🧪 LATEST TECH SECTION
// --------------------------------------------------------------------
class LatestTechSection extends StatelessWidget {
  const LatestTechSection({super.key});

  static final _items = [
    _TechItem(
      title: 'IMAX',
      imagePath: 'assets/images/image1.png',
      caption: 'ภาพใหญ่ คมชัด',
    ),
    _TechItem(
      title: '4DX',
      imagePath: 'assets/images/image2.png',
      caption: 'ที่นั่งสั่น ลม น้ำ',
    ),
    _TechItem(
      title: 'Dolby Atmos',
      imagePath: 'assets/images/image3.png',
      caption: 'เสียงรอบทิศ',
    ),
    _TechItem(
      title: 'Kids Cinema',
      imagePath: 'assets/images/image4.png',
      caption: 'เหมาะกับเด็ก',
    ),
    _TechItem(
      title: 'GLS',
      imagePath: 'assets/images/image5.png',
      caption: 'Giant Laser Screen',
    ),
    _TechItem(
      title: 'ScreenX',
      imagePath: 'assets/images/image6.png',
      caption: 'จอพาโนรามา',
    ),
    _TechItem(
      title: 'LaserPlex',
      imagePath: 'assets/images/image7.png',
      caption: 'โปรเจกเตอร์เลเซอร์',
    ),
    _TechItem(
      title: 'LED Cinema',
      imagePath: 'assets/images/image8.png',
      caption: 'จอสว่าง คมชัด',
    ),
    _TechItem(
      title: 'VIP Cinema',
      imagePath: 'assets/images/image9.png',
      caption: 'หรูหรา สบาย',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'เทคโนโลยีล่าสุด',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) => _TechCard(item: _items[i]),
          ),
        ),
      ],
    );
  }
}

class _TechItem {
  final String title;
  final String caption;
  final String imagePath;
  const _TechItem({
    required this.title,
    required this.imagePath,
    required this.caption,
  });
}

class _TechCard extends StatelessWidget {
  final _TechItem item;
  const _TechCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  height: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --------------------------------------------------------------------

// 🔎 MOVIE SEARCH DELEGATE
// --------------------------------------------------------------------
class MovieSearchDelegate extends SearchDelegate<String> {
  final List<Movie> source;
  MovieSearchDelegate({required this.source});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white60),
        border: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
    );
  }

  @override
  String? get searchFieldLabel => 'ค้นหาหนัง…';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(color: Colors.white, fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          tooltip: 'ล้าง',
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'ย้อนกลับ',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  List<Movie> _filter() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((m) {
          final title = m.title.toLowerCase();
          final genre = m.genre.toLowerCase();
          return title.contains(q) || genre.contains(q);
        })
        .toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) => _resultsList(context);

  @override
  Widget buildResults(BuildContext context) => _resultsList(context);

  Widget _resultsList(BuildContext context) {
    final results = _filter();
    if (results.isEmpty) {
      return const Center(
        child: Text('ไม่พบผลลัพธ์', style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (ctx, i) {
        final m = results[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 60,
              child: CachedNetworkImage(
                imageUrl: m.poster,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFF1E1E1E)),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF1E1E1E)),
              ),
            ),
          ),
          title: Text(
            m.title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            m.genre,
            style: const TextStyle(color: Colors.white70),
          ),
          onTap: () {
            close(context, m.title);
            Navigator.pushNamed(
              context,
              '/showtimes',
              arguments: m.toMap(),
            );
          },
        );  
      },
    );
  }
}