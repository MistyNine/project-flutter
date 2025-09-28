import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math';

// ✅ ปรับพาธตามโปรเจ็กต์ของคุณ
import 'package:movie_cinema/seat_screen.dart';

class ShowtimesScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const ShowtimesScreen({super.key, required this.movie});

  @override
  State<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends State<ShowtimesScreen> {
  late String _selectedDate;
  List<Map<String, dynamic>> _showtimes = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String? _selectedFilter;

  late String _staticRandomRating;
  late String _staticRandomDuration;

  Map<String, dynamic> _movieDetails = {};
  bool _isDetailsLoading = true;

  bool _isPlotExpanded = false;

  String _getRandomRating() => (Random().nextInt(6) + 13).toString();
  String _getRandomDuration() => (Random().nextInt(51) + 100).toString();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th', null);
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _staticRandomRating = _getRandomRating();
    _staticRandomDuration = _getRandomDuration();
    _fetchShowtimes();
    _fetchMovieDetails();
  }

  // ------------------------------------
  // MARK: Data Fetching
  // ------------------------------------

  Future<void> _fetchMovieDetails() async {
    setState(() {
      _isDetailsLoading = true;
      _movieDetails = {};
    });

    try {
      final detailsRef = FirebaseFirestore.instance.collection('movieDetails');
      final movieTitle = (widget.movie['title'] as String?)?.trim();

      if (movieTitle == null || movieTitle.isEmpty) {
        setState(() => _movieDetails = {'plot': 'ไม่มีเรื่องย่อให้บริการ'});
        return;
      }

      final docSnapshot = await detailsRef.doc(movieTitle).get();

      if (!mounted) return;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() => _movieDetails = docSnapshot.data()!);
      } else {
        setState(() => _movieDetails = {'plot': 'ไม่มีเรื่องย่อให้บริการ'});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _movieDetails = {'plot': 'เกิดข้อผิดพลาดในการดึงเรื่องย่อ'});
    } finally {
      if (mounted) setState(() => _isDetailsLoading = false);
    }
  }

  Future<void> _fetchShowtimes() async {
    setState(() {
      _isLoading = true;
      _showtimes = [];
    });

    try {
      final showtimesRef = FirebaseFirestore.instance.collection('showtimes');
      final movieTitle = (widget.movie['title'] as String?)?.trim();

      if (movieTitle == null || movieTitle.isEmpty) {
        setState(() => _showtimes = []);
        return;
      }

      final querySnapshot = await showtimesRef
          .where('movieTitle', isEqualTo: movieTitle)
          .where('date', isEqualTo: _selectedDate)
          .get();

      if (!mounted) return;

      final docs = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>))
          .toList();

      setState(() => _showtimes = docs);
    } catch (e) {
      if (mounted) {
        // ถ้า error ให้ขึ้นรายการว่าง
        setState(() => _showtimes = []);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DateTime> _getAvailableDates() =>
      List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

  void _selectDate(DateTime date) {
    final newDate = DateFormat('yyyy-MM-dd').format(date);
    if (_selectedDate != newDate) {
      setState(() {
        _selectedDate = newDate;
        _selectedFilter = null;
        _searchQuery = '';
      });
      _fetchShowtimes();
    }
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'จ.';
      case DateTime.tuesday:
        return 'อ.';
      case DateTime.wednesday:
        return 'พ.';
      case DateTime.thursday:
        return 'พฤ.';
      case DateTime.friday:
        return 'ศ.';
      case DateTime.saturday:
        return 'ส.';
      case DateTime.sunday:
        return 'อา.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildMovieDetailSection()),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  // ------------------------------------
  // MARK: UI Components
  // ------------------------------------

  Widget _buildMovieDetailSection() {
    final displayRating = widget.movie['rating'] ?? _staticRandomRating;
    final displayDuration = _staticRandomDuration;

    final String plot = _isDetailsLoading
        ? 'กำลังโหลด...'
        : (_movieDetails['plot'] as String?) ?? 'ไม่มีเรื่องย่อให้บริการ';

    final int maxLines = _isPlotExpanded ? 999 : 4;

    final bool canBeExpanded = plot.length > 200 &&
        !_isDetailsLoading &&
        plot != 'ไม่มีเรื่องย่อให้บริการ' &&
        plot != 'เกิดข้อผิดพลาดในการดึงเรื่องย่อ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (widget.movie['title'] as String?) ?? 'N/A',
            style: GoogleFonts.kanit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${widget.movie['genre'] ?? 'N/A'} | Rate: $displayRating | ',
                style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
              ),
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '$displayDuration นาที',
                style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'เรื่องย่อ',
            style: GoogleFonts.kanit(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            plot,
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          if (canBeExpanded)
            GestureDetector(
              onTap: () => setState(() => _isPlotExpanded = !_isPlotExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _isPlotExpanded ? 'ย่อหน้า' : 'ดูเพิ่มเติม',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final poster = (widget.movie['poster'] as String?) ?? '';
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 350,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: poster.isEmpty
                  ? Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: const Icon(Icons.movie, color: Colors.white, size: 80),
                    )
                  : CachedNetworkImage(
                      imageUrl: poster,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.movie, color: Colors.white, size: 80),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final availableDates = _getAvailableDates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            DateFormat('MMM', 'th').format(DateTime.now()),
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: availableDates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final date = availableDates[i];
              final formattedDate = DateFormat('yyyy-MM-dd').format(date);
              final isSelected = _selectedDate == formattedDate;

              return GestureDetector(
                onTap: () => _selectDate(date),
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.redAccent : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.redAccent : Colors.white10,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeekday(date.weekday),
                        style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSearchBar(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _buildFilterBar(),
        ),
        const SizedBox(height: 20),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              )
            : _buildShowtimesList(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            if (_selectedFilter != null) _selectedFilter = null;
          });
        },
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.white54),
          hintText: 'ค้นหา',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.filter_list, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = ['IMAX', '4DX', 'Screen X', 'Kids', 'LED', 'Dolby Atmos', 'Pet Cinema'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filterName = filters[i];
          final isSelected = _selectedFilter == filterName;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = isSelected ? null : filterName;
                _searchQuery = '';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.redAccent : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(filterName, style: GoogleFonts.kanit(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------
  // MARK: Showtimes List Builder
  // ------------------------------------

  Widget _buildShowtimesList() {
    // 1) กรองข้อมูลอย่างปลอดภัย
    final filteredShowtimes = _showtimes.where((st) {
      final cinemaName = (st['cinema'] as String?) ?? '';
      final screenType = (st['screenType'] as String?) ?? '';
      final matchesSearch =
          cinemaName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == null ||
          (screenType.isNotEmpty &&
              screenType.toUpperCase().contains(_selectedFilter!.toUpperCase()));
      return matchesSearch && matchesFilter;
    }).toList();

    if (_showtimes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: Text(
            'ไม่มีรอบฉายสำหรับวันนี้ ${DateFormat('d MMMM y', 'th').format(DateTime.parse(_selectedDate))}',
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (filteredShowtimes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 32.0, right: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ไม่พบโรงภาพยนตร์หรือรอบฉายที่ตรงตามเงื่อนไข',
                style: GoogleFonts.kanit(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    // 2) Group ด้วย key = cinema|screenType
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final st in filteredShowtimes) {
      final cinemaName = (st['cinema'] as String?) ?? 'N/A Cinema';
      final screenType = (st['screenType'] as String?) ?? '2D';
      final key = '$cinemaName|$screenType';
      (grouped[key] ??= []).add(st);
    }

    // 3) Sort group key
    final sortedGroups = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'ใกล้เคียง',
              style: GoogleFonts.kanit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...sortedGroups.map((entry) {
            final parts = entry.key.split('|');
            final cinemaName = parts[0];
            final screenType = parts.length > 1 ? parts[1] : '2D';
            final times = entry.value;

            if (times.isEmpty) return const SizedBox.shrink();

            // sort ตาม time (string HH:mm)
            final sortedTimes = List<Map<String, dynamic>>.from(times)
              ..sort((a, b) => ((a['time'] as String?) ?? '23:59')
                  .compareTo(((b['time'] as String?) ?? '23:59')));

            final location = (times.first['location'] as String?) ?? 'กรุงเทพมหานคร';

            return _CinemaCard(
              key: ValueKey(entry.key),
              movieTitle: (widget.movie['title'] as String?) ?? 'N/A Movie',
              cinemaName: cinemaName,
              location: location,
              showtimes: sortedTimes,
              screenType: screenType,
              selectedDate: _selectedDate,
              // ✅ ส่งโปสเตอร์ไปการ์ด
              posterUrl: widget.movie['poster'] as String?,
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ------------------------------------
// MARK: _CinemaCard Widget (Stateful)
// ------------------------------------

class _CinemaCard extends StatefulWidget {
  final String movieTitle;
  final String cinemaName;
  final String location;
  final List<Map<String, dynamic>> showtimes;
  final String screenType;
  final String selectedDate;

  // ✅ เพิ่มตัวรับโปสเตอร์
  final String? posterUrl;

  const _CinemaCard({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.location,
    required this.showtimes,
    required this.screenType,
    required this.selectedDate,
    this.posterUrl,
  });

  @override
  State<_CinemaCard> createState() => _CinemaCardState();
}

class _CinemaCardState extends State<_CinemaCard> {
  bool _isFavorite = false;
  bool _isExpanded = true;

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final String _favoriteCollectionName = 'user_favorites';

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  // ------------------------------------
  // MARK: Favorite Logic
  // ------------------------------------

  Future<void> _loadFavoriteStatus() async {
    if (_currentUserId == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection(_favoriteCollectionName)
          .doc(_currentUserId);
      final docSnapshot = await docRef.get();

      if (!mounted) return;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final favorites =
            (docSnapshot.data()!['favoriteCinemas'] as List<dynamic>? ?? [])
                .cast<String>();
        setState(() => _isFavorite = favorites.contains(widget.cinemaName));
      }
    } catch (e) {
      debugPrint('Error loading favorite status for $_currentUserId: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเพิ่มรายการโปรด')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection(_favoriteCollectionName)
        .doc(_currentUserId);
    final wasFavorite = _isFavorite;

    setState(() => _isFavorite = !wasFavorite);

    try {
      if (!wasFavorite) {
        await docRef.set({
          'favoriteCinemas': FieldValue.arrayUnion([widget.cinemaName])
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.cinemaName} ถูกเพิ่มในรายการโปรดแล้ว ⭐')),
          );
        }
      } else {
        await docRef.update({
          'favoriteCinemas': FieldValue.arrayRemove([widget.cinemaName])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.cinemaName} ถูกนำออกจากรายการโปรดแล้ว')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = wasFavorite);
      debugPrint('Firestore Error (Favorite Toggle): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกสถานะ! (ตรวจสอบสิทธิ์ Firestore)')),
      );
    }
  }

  // ------------------------------------
  // MARK: Build UI helpers
  // ------------------------------------

  Widget _buildCinemaLogo(String cinemaName) {
    String logoText = '';
    Color logoColor = Colors.white;

    if (cinemaName.contains('พารากอน')) {
      logoText = 'PARAGON';
      logoColor = const Color(0xFFF9A825);
    } else if (cinemaName.contains('ไอคอน')) {
      logoText = 'ICON';
      logoColor = const Color(0xFF90A4AE);
    } else if (cinemaName.contains('เมกา')) {
      logoText = 'MEGA';
      logoColor = const Color(0xFF4DB6AC);
    }

    if (logoText.isEmpty) return const SizedBox.shrink();

    return Text(
      logoText,
      style: GoogleFonts.kanit(
          fontSize: 10, color: logoColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAttributeChip(String label, {Color? bgColor}) {
    if (label.isEmpty) return const SizedBox.shrink();

    Color finalBg = bgColor ?? const Color(0xFF333333);

    if (label.contains('IMAX') ||
        label.contains('พากย์ไทย') ||
        label.contains('ซับอังกฤษ')) {
      finalBg = Colors.redAccent;
    } else if (label.contains('4DX')) {
      finalBg = Colors.blue.shade900;
    } else if (label.contains('Kids')) {
      finalBg = Colors.pink.shade400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: finalBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.kanit(
            fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeChip(Map<String, dynamic> showtime, BuildContext context) {
    final timeString = (showtime['time'] as String?) ?? 'N/A';
    if (timeString == 'N/A') return const SizedBox.shrink();

    final bool isToday =
        DateFormat('yyyy-MM-dd').format(DateTime.now()) == widget.selectedDate;

    DateTime? showtimeDateTime;
    try {
      showtimeDateTime = DateFormat('yyyy-MM-dd HH:mm')
          .parse('${widget.selectedDate} $timeString');
    } catch (_) {
      return const SizedBox.shrink();
    }

    final bool isPast = isToday && showtimeDateTime.isBefore(DateTime.now());

    final Color backgroundColor =
        isPast ? Colors.grey[900]! : const Color(0xFF222222);
    final Color textColor = isPast ? Colors.white30 : Colors.white;
    final Border border =
        isPast ? Border.all(color: Colors.transparent) : Border.all(color: Colors.white, width: 1);

    void _goToSeatScreen() {
      // ✅ ส่ง showtimeData แบบ Map<String,dynamic> ชัดเจน + โปสเตอร์
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeatScreen(
            movieTitle: widget.movieTitle,
            cinemaName: widget.cinemaName,
            screenType: widget.screenType,
            selectedTime: timeString,
            selectedDate: widget.selectedDate,
            showtimeData: showtime,
            posterUrl: widget.posterUrl, // ✅ ส่งต่อโปสเตอร์
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: isPast,
      child: GestureDetector(
        onTap: _goToSeatScreen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Text(
            timeString,
            style: GoogleFonts.kanit(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showtimes.isEmpty) return const SizedBox.shrink();

    final firstShowtime = widget.showtimes.first;
    final langCode = (firstShowtime['language'] as String?) ?? '';
    final subCode = (firstShowtime['subtitle'] as String?) ?? '';

    String langAndSubChip = '';
    String audioText = '';
    String subtitleText = '';

    if (langCode == 'TH') audioText = 'พากย์ไทย';
    if (langCode == 'EN') audioText = 'เสียงอังกฤษ';
    if (subCode == 'TH') subtitleText = 'ซับไทย';
    if (subCode == 'EN') subtitleText = 'ซับอังกฤษ';

    if (audioText.isNotEmpty && subtitleText.isNotEmpty) {
      langAndSubChip = '$audioText / $subtitleText';
    } else if (audioText.isNotEmpty) {
      langAndSubChip = audioText;
    } else if (subtitleText.isNotEmpty) {
      langAndSubChip = subtitleText;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อโรง + ปุ่ม favorite + ปุ่มยุบ/ขยาย
          Row(
            children: [
              _buildCinemaLogo(widget.cinemaName),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.cinemaName,
                  style: GoogleFonts.kanit(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _toggleFavorite,
                child: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  size: 20,
                  color: _isFavorite ? Colors.yellow.shade700 : Colors.white54,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.location,
                style: GoogleFonts.kanit(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),

          // ส่วนยุบ/ขยาย
          Visibility(
            visible: _isExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  children: [
                    _buildAttributeChip(widget.screenType),
                    if (langAndSubChip.isNotEmpty) _buildAttributeChip(langAndSubChip),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // เวลารอบฉาย
          Visibility(
            visible: _isExpanded,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.showtimes
                  .map((st) => _buildTimeChip(st, context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
