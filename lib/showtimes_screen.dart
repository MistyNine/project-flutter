import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Still useful for poster thumbnails
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:video_player/video_player.dart'; // Import video_player

class ShowtimesScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const ShowtimesScreen({super.key, required this.movie});

  @override
  State<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends State<ShowtimesScreen> {
  late String _selectedDate;
  List<dynamic> _showtimes = [];
  bool _isLoading = true;

  // Video player specific variables
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlayingVideo = false; // To control video playback

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th', null);
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchShowtimes();

    // Initialize video player
    // You should replace this with the actual video URL from your movie data
    final videoUrl = widget.movie['trailer_url'] ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'; // Placeholder
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
      // Ensure the first frame is shown and then play for autoplay, or just show the first frame
      // _videoController.play(); // Uncomment to autoplay
      _videoController.setLooping(true); // Loop the video
      _videoController.setVolume(0.0); // Start with no volume
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _fetchShowtimes() async {
    setState(() {
      _isLoading = true;
      _showtimes = [];
    });
    try {
      final showtimesRef = FirebaseFirestore.instance.collection('showtimes');
      final querySnapshot = await showtimesRef
          .where('movieTitle', isEqualTo: widget.movie['title'])
          .where('date', isEqualTo: _selectedDate)
          .get();

      setState(() {
        _showtimes = querySnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print("Error fetching showtimes: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent, // Ensure transparent to see video
      expandedHeight: 350,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoController.value.isPlaying) {
                            _videoController.pause();
                            _isPlayingVideo = false;
                          } else {
                            _videoController.play();
                            _isPlayingVideo = true;
                          }
                        });
                      },
                      child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      ),
                    );
                  } else {
                    return CachedNetworkImage( // Fallback to poster while video loads
                      imageUrl: widget.movie['poster'] ?? '',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    );
                  }
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Dark overlay for text readability
              ),
            ),
            if (!_isPlayingVideo && _videoController.value.isInitialized)
              const Center(
                child: Icon(Icons.play_circle_filled, size: 80, color: Colors.white70),
              ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d ก.ย. y').format(DateTime.now()),
                    style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie['title'] ?? 'N/A',
                    style: GoogleFonts.kanit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(widget.movie['genre'] ?? 'N/A'),
                      const SizedBox(width: 8),
                      _buildInfoChip('Rate: ${widget.movie['rating'] ?? 'G'}'),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.movie['runtime'] ?? 'N/A'} นาที',
                        style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The back button is provided by SliverAppBar itself
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.kanit(fontSize: 12, color: Colors.white70),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // This date is hardcoded in the image, you might want to adjust
                '${DateFormat('MMM. y').format(DateTime.now())}',
                style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'วันนี้ ${DateFormat('d').format(DateTime.now())}',
                  style: GoogleFonts.kanit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildFilterBar(),
          const SizedBox(height: 20),
          _buildShowtimesList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
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
    final filters = ['IMAX', '4DX', 'Screen X', 'Kids', 'LED'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              filters[i],
              style: GoogleFonts.kanit(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShowtimesList() {
    if (_showtimes.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีรอบฉายสำหรับวันนี้',
          style: GoogleFonts.kanit(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    final groupedByCinema = <String, List<dynamic>>{};
    for (var showtime in _showtimes) {
      final cinemaName = showtime['cinema'] as String;
      if (!groupedByCinema.containsKey(cinemaName)) {
        groupedByCinema[cinemaName] = [];
      }
      groupedByCinema[cinemaName]!.add(showtime);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align "ใกล้เคียง"
      children: [
        Text(
          'ใกล้เคียง',
          style: GoogleFonts.kanit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ...groupedByCinema.keys.map((cinemaName) {
          final times = groupedByCinema[cinemaName]!;
          return _CinemaCard(
            cinemaName: cinemaName,
            location: 'กรุงเทพมหานคร', // You might fetch this from another collection
            times: times,
          );
        }).toList(),
      ],
    );
  }
}

class _CinemaCard extends StatelessWidget {
  final String cinemaName;
  final String location;
  final List<dynamic> times;

  const _CinemaCard({
    required this.cinemaName,
    required this.location,
    required this.times,
  });

  @override
  Widget build(BuildContext context) {
    // Sort times to ensure correct order
    times.sort((a, b) => a['time'].compareTo(b['time']));

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
          Row(
            children: [
              Text(
                cinemaName,
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                location,
                style: GoogleFonts.kanit(color: Colors.white54, fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.star_border, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              const Icon(Icons.share, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.map((showtime) {
              return GestureDetector(
                onTap: () {
                  // TODO: Navigate to seat selection screen with showtime details
                  Navigator.pushNamed(context, '/seats', arguments: {
                    'showtime': showtime,
                    'movieTitle': showtime['movieTitle'],
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(8),
                    // Highlight the first showtime as an example for "20:50"
                    border: times.indexOf(showtime) == 0 && cinemaName == 'ไอคอน ซีเนคอนิค' // Example logic to highlight
                        ? Border.all(color: Colors.yellow, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        showtime['time'],
                        style: GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // You'll need to pass 'format' or 'language' from Firestore
                      Text(
                        'IMAX LASER • EN • CC TH', // Example combined format
                        style: GoogleFonts.kanit(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}