import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatScreen extends StatefulWidget {
  const SeatScreen({super.key});

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  Map<String, dynamic>? _selectedShowtime;
  String? _movieTitle;
  List<dynamic> _seats = [];
  bool _isLoading = true;
  Set<String> _selectedSeats = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedShowtime == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _selectedShowtime = args['showtime'];
      _movieTitle = args['movieTitle'];
      _fetchSeats();
    }
  }

  Future<void> _fetchSeats() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final seatRef = FirebaseFirestore.instance.collection('seats');
      final querySnapshot = await seatRef
          .where('showtimeId', isEqualTo: _selectedShowtime!['id'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _seats = querySnapshot.docs.first.data()['layout'];
        });
      }
    } catch (e) {
      print("Error fetching seats: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSeatSelection(String seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _movieTitle ?? 'เลือกที่นั่ง',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _selectedShowtime?['cinema'] ?? 'N/A',
                      style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _selectedShowtime?['time'] ?? 'N/A',
                      style: GoogleFonts.kanit(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    _buildScreenIndicator(),
                    const SizedBox(height: 20),
                    _buildSeatLayout(),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _selectedSeats.isNotEmpty
                          ? () {
                              // TODO: Implement booking logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('คุณเลือกที่นั่ง: ${_selectedSeats.join(', ')}'),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        'ยืนยันการจอง',
                        style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScreenIndicator() {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white12, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
    );
  }

  Widget _buildSeatLayout() {
    return Column(
      children: _seats.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: (row as List).map((seat) {
            if (seat == 'X') {
              return SizedBox(width: 30, height: 30);
            }
            final isSelected = _selectedSeats.contains(seat);
            final isAvailable = seat != 'X';
            return GestureDetector(
              onTap: isAvailable
                  ? () => _toggleSeatSelection(seat)
                  : null,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.redAccent
                      : isAvailable
                          ? Colors.grey[800]
                          : Colors.red[900],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    seat,
                    style: GoogleFonts.kanit(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}