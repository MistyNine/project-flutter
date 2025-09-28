// lib/seat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ⭐️ เพิ่ม: สำหรับดึงข้อมูลการจองจริง

import 'payment_screen.dart'; 

// ===== Models =====
enum SeatStatus { available, reserved, selected }

class SeatModel {
  final String id;
  final String row;
  final int column;
  SeatStatus status;
  SeatModel({
    required this.id,
    required this.row,
    required this.column,
    this.status = SeatStatus.available,
  });
}

class RowModel {
  final String rowName;
  final List<SeatModel> seats;
  RowModel({required this.rowName, required this.seats});
}

// ===== Seat Screen =====
class SeatScreen extends StatefulWidget {
  final String movieTitle;
  final String cinemaName;
  final String screenType;
  final String selectedTime;
  final String selectedDate;
  final Map<String, dynamic> showtimeData;

  final String? posterUrl;

  const SeatScreen({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.screenType,
    required this.selectedTime,
    required this.selectedDate,
    required this.showtimeData,
    this.posterUrl,
  });

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  // ===== Config =====
  static const int maxSeatsSelection = 8;

  static const Map<String, double> seatPrices = {
    'Normal': 260.0, // C–G
    'Premium': 290.0, // A,B
    'VIP': 800.0, // VP
  };

  static const Color normalRed = Color(0xFFC62828);
  static const Color premiumBlue = Color(0xFF2B3A8C);
  static const Color vipRed = Color(0xFFE53935);
  static const bool reservedAsIcon = true;

  // ⭐️ ตัวแปรสถานะ
  bool _isLoading = true; 
  List<RowModel> _seatLayout = []; // กำหนดค่าเริ่มต้น
  Map<String, SeatModel> _seatById = {}; // กำหนดค่าเริ่มต้น
  final List<String> _selectedSeatIds = [];
  
  // ที่นั่งที่ถูกบล็อกถาวร (ไม่ใช่การจอง)
  final Set<String> _blockedSeats = {'F6', 'F7'}; 

  // ⭐️ ฟังก์ชันใหม่: ดึงข้อมูลการจองจริงจาก Firestore
  Future<void> _loadSeatLayout() async {
    setState(() {
      _isLoading = true;
    });

    // 1. สร้าง Query เพื่อค้นหาตั๋วสำหรับการฉายรอบนี้โดยเฉพาะ
    final showtimeQuery = FirebaseFirestore.instance.collection('tickets')
      .where('movieTitle', isEqualTo: widget.movieTitle)
      .where('selectedDate', isEqualTo: widget.selectedDate)
      .where('selectedTime', isEqualTo: widget.selectedTime)
      .where('cinemaName', isEqualTo: widget.cinemaName);

    try {
      final snapshot = await showtimeQuery.get();
      
      final bookedIdsFromDB = <String>{};
      
      // 2. รวบรวมที่นั่งที่ถูกจองแล้วจากทุกตั๋วที่พบ
      for (final doc in snapshot.docs) {
        // ต้องมั่นใจว่า 'selectedSeats' เป็น List<String> ใน Firestore
        final seatsData = doc.data()['selectedSeats'];
        if (seatsData is List) {
          final seats = List<String>.from(seatsData.map((s) => s.toString()));
          bookedIdsFromDB.addAll(seats);
        }
      }
      
      // 3. สร้าง Layout จริงด้วยข้อมูลที่ดึงมา
      setState(() {
        _seatLayout = _generateLayout(bookedIdsFromDB); 
        _seatById = { for (final row in _seatLayout) for (final s in row.seats) s.id: s };
        _isLoading = false;
      });
    } catch (e) {
      // จัดการข้อผิดพลาดในการโหลดข้อมูล
      // ignore: avoid_print
      print("Error loading seats from Firestore: $e");
      setState(() {
        _isLoading = false;
      });
      // อาจจะแสดง AlertDialog หรือ SnackBar แจ้งผู้ใช้
    }
  }


  // ===== Layout: สร้าง Layout โดยรับข้อมูลที่จองแล้วเข้ามา =====
  // ⭐️ แก้ไขให้รับ Set ของ ID ที่จองแล้วเข้ามา
  List<RowModel> _generateLayout(Set<String> bookedIdsFromDB) {
    const rows = ['G', 'F', 'E', 'D', 'C', 'B', 'A', 'VP'];

    // ⭐️ รวม blocked (ถาวร) กับ booked (จาก DB)
    final finalReservedIds = _blockedSeats.union(bookedIdsFromDB);

    RowModel buildRow(String rowName) {
      final seats = <SeatModel>[];
      final totalCols = (rowName == 'VP')
          ? 6
          : (rowName == 'A' || rowName == 'B')
              ? 8
              : 12;

      for (int col = 1; col <= totalCols; col++) {
        final id = '$rowName$col';
        seats.add(SeatModel(
          id: id,
          row: rowName,
          column: col,
          status: finalReservedIds.contains(id)
              ? SeatStatus.reserved // ⭐️ ใช้รายการที่รวม DB Data แล้ว
              : SeatStatus.available,
        ));
      }
      return RowModel(rowName: rowName, seats: seats);
    }

    return rows.map(buildRow).toList();
  }

  // ⭐️ แก้ไข initState ให้เรียก _loadSeatLayout
  @override
  void initState() {
    super.initState();
    _loadSeatLayout(); 
  }

  String _rowFromId(String seatId) {
    final m = RegExp(r'^[A-Z]+').firstMatch(seatId);
    return m?.group(0) ?? seatId[0];
  }

  SeatModel? _findSeat(String id) => _seatById[id];

  double get totalPrice {
    double total = 0;
    for (final id in _selectedSeatIds) {
      final row = _rowFromId(id);
      final tier = (row == 'VP')
          ? 'VIP'
          : ((row == 'A' || row == 'B') ? 'Premium' : 'Normal');
      total += seatPrices[tier]!;
    }
    return total;
  }

  Color _seatColor(String row, SeatStatus status) {
    Color base;
    if (row == 'VP') {
      base = vipRed;
    } else if (row == 'A' || row == 'B') {
      base = premiumBlue;
    } else {
      base = normalRed;
    }
    if (status == SeatStatus.selected) return base;
    if (status == SeatStatus.available) return base.withOpacity(0.85);
    return base;
  }

  Size _seatSize() => const Size(26, 26);

  void _selectSeat(SeatModel s) {
    s.status = SeatStatus.selected;
    _selectedSeatIds.add(s.id);
  }

  void _deselectSeat(SeatModel s) {
    s.status = SeatStatus.available;
    _selectedSeatIds.remove(s.id);
  }

  void _resortSelectedIds() {
    _selectedSeatIds.sort((a, b) {
      final ra = _rowFromId(a), rb = _rowFromId(b);
      if (ra != rb) return ra.compareTo(rb);
      final ca = int.parse(a.replaceAll(RegExp(r'^[A-Z]+'), ''));
      final cb = int.parse(b.replaceAll(RegExp(r'^[A-Z]+'), ''));
      return ca.compareTo(cb);
    });
  }

  void _onSeatTapped(SeatModel s) {
    if (s.status == SeatStatus.reserved) return;
    setState(() {
      if (s.status == SeatStatus.selected) {
        _deselectSeat(s);
      } else {
        if (_selectedSeatIds.length >= maxSeatsSelection) {
          _showMaxSelectionDialog();
          return;
        }
        _selectSeat(s);
      }
      _resortSelectedIds();
    });
  }

  // VIP โซฟา: แตะซ้าย/ขวาเลือกได้เป็นที่นั่งเดี่ยว
  void _onSofaTapped(SeatModel tappedSeat) {
    if (tappedSeat.status == SeatStatus.reserved) return;

    setState(() {
      if (tappedSeat.status == SeatStatus.selected) {
        _deselectSeat(tappedSeat);
      } else {
        if (_selectedSeatIds.length >= maxSeatsSelection) {
          _showMaxSelectionDialog();
          return;
        }
        _selectSeat(tappedSeat);
      }
      _resortSelectedIds();
    });
  }

  void _showMaxSelectionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('จำกัดการเลือกที่นั่ง', style: GoogleFonts.kanit()),
        content: Text('เลือกได้สูงสุด $maxSeatsSelection ที่นั่งต่อครั้ง',
            style: GoogleFonts.kanit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง', style: GoogleFonts.kanit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ====== DEBUG + NAVIGATE (ส่วนที่ถูกแก้ไข) ======
  void _onConfirmBooking() async { 
    if (_selectedSeatIds.isEmpty) return;

    final dynamic rawPosterFallback =
        widget.showtimeData['poster'] ??
        widget.showtimeData['posterUrl'] ??
        widget.showtimeData['poster_path'];

    final posterClean = (widget.posterUrl ??
            (rawPosterFallback is String ? rawPosterFallback : null))
        ?.trim()
        .replaceAll('"', '')
        .replaceAll('\u200B', '');

    // DEBUG
    // ignore: avoid_print
    print(
      '[SeatScreen] push PaymentScreen with poster="$posterClean", '
      'movie="${widget.movieTitle}", cinema="${widget.cinemaName}", '
      'screen="${widget.screenType}", date=${widget.selectedDate}, time=${widget.selectedTime}, '
      'seats=$_selectedSeatIds, total=$totalPrice',
    );

    // ⭐️ ใช้ await เพื่อรอผลลัพธ์จาก PaymentScreen
    final seatsToReserve = List<String>.from(_selectedSeatIds); // เก็บ ID ที่กำลังจะจองไว้ก่อน
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          selectedSeats: seatsToReserve, // ใช้ seatsToReserve
          totalPrice: totalPrice,
          movieTitle: widget.movieTitle,
          cinemaName: widget.cinemaName,
          screenType: widget.screenType,
          selectedDate: widget.selectedDate,
          selectedTime: widget.selectedTime,
          posterUrl: posterClean,
        ),
      ),
    );

    // ⭐️ เมื่อกลับมาจาก PaymentScreen: ถ้ามีการจองสำเร็จ
    if (result == true) {
      setState(() {
        // 1. อัปเดตสถานะที่นั่งที่เพิ่งจองสำเร็จทั้งหมดให้เป็น RESERVED
        for (final seatId in seatsToReserve) {
          final seat = _findSeat(seatId);
          if (seat != null) {
            seat.status = SeatStatus.reserved;
          }
        }
        // 2. ล้างรายการที่นั่งที่ถูกเลือกชั่วคราว
        _selectedSeatIds.clear();
        
        // 3. แสดง SnackBar เพื่อยืนยัน
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('จองที่นั่ง ${seatsToReserve.join(', ')} สำเร็จแล้ว!', 
              style: GoogleFonts.kanit(color: Colors.white)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      });
      // 💡 ไม่ต้องเรียก _loadSeatLayout() ซ้ำ เพราะเราอัปเดตสถานะในหน้าจอทันทีแล้ว
    } else {
      // ถ้าไม่ได้จองสำเร็จ (เช่น กด Back หรือยกเลิก) _selectedSeatIds จะถูกคงไว้
    }
  }

  // ⭐️ เพิ่ม Loading State ใน Build
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
        return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
                child: CircularProgressIndicator(color: Colors.redAccent),
            ),
        );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 6),
          _buildScreenArc(),
          const SizedBox(height: 8),
          Expanded(child: _horizontalSeatArea()),
          const SizedBox(height: 6),
          _priceCardsCompact(),
          const SizedBox(height: 8),
          _bottomBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final details = widget.showtimeData['details'];
    final selectedTime = widget.selectedTime;
    final selectedDate = widget.selectedDate;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.movieTitle,
                  style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              Text('${widget.cinemaName} | ${widget.screenType}',
                  style: GoogleFonts.kanit(color: Colors.white70)),
              if (details != null && details.toString().isNotEmpty)
                Text(details.toString(),
                    style: GoogleFonts.kanit(color: Colors.white70)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text('ส. $selectedDate',
                        style: GoogleFonts.kanit(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(selectedTime,
                        style: GoogleFonts.kanit(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenArc() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A2C25), Color(0xFF1E1A18)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(320, 40)),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('หน้าจอ',
              style: GoogleFonts.kanit(color: Colors.white70, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _horizontalSeatArea() {
    return ScrollConfiguration(
      behavior: const _NoGlowScrollBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _seatLayout.map(_buildSeatRow).toList(),
        ),
      ),
    );
  }

  Widget _buildSeatRow(RowModel rowModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rowLabel(rowModel.rowName),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildRowSeatsWithSpacing(rowModel),
          ),
          const SizedBox(width: 6),
          _rowLabel(rowModel.rowName),
        ],
      ),
    );
  }

  List<Widget> _buildRowSeatsWithSpacing(RowModel rowModel) {
    final List<Widget> seatWidgets = [];
    final isVP = rowModel.rowName == 'VP';
    final totalSeats = rowModel.seats.length;

    for (int i = 0; i < totalSeats; i++) {
      final seat = rowModel.seats[i];

      if (isVP) {
        // widget เดียวต่อ "คู่" (เลขคี่คือซ้าย)
        final isLeftSeat = (seat.column % 2) == 1;
        if (!isLeftSeat) continue;

        final SeatModel? right = _findSeat('VP${seat.column + 1}');

        seatWidgets.add(
          LayoutBuilder(
            builder: (context, _) {
              const pairWidth = 64.0;
              const pairHeight = 32.0;
              return _SofaGlyph(
                leftSeat: seat,
                rightSeat: right,
                colorLeft: _seatColor(seat.row, seat.status),
                colorRight: _seatColor('VP', right?.status ?? SeatStatus.available),
                onTapLeft: () => _onSofaTapped(seat),
                onTapRight: () { if (right != null) _onSofaTapped(right); },
                size: pairWidth,
                pairHeightOverride: pairHeight,
              );
            },
          ),
        );
      } else {
        // ที่นั่งเดี่ยว (C–G, A, B)
        seatWidgets.add(_seatButton(seat));
      }

      // Spacing
      if (isVP) {
        if (i == 0 || i == 2) seatWidgets.add(const SizedBox(width: 20));
      } else if (totalSeats == 12 && i == 5) {
        seatWidgets.add(const SizedBox(width: 10));
      } else if (totalSeats == 8 && i == 3) {
        seatWidgets.add(const SizedBox(width: 10));
      }
    }

    return seatWidgets;
  }

  Widget _rowLabel(String row) => SizedBox(
        width: 24,
        child: Text(
          row,
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(color: Colors.white54, fontWeight: FontWeight.w700),
        ),
      );

  Widget _seatButton(SeatModel seat) {
    final color = _seatColor(seat.row, seat.status);
    final size = _seatSize();
    final isReservedIcon = reservedAsIcon && seat.status == SeatStatus.reserved;
    final isSelectedIcon = seat.status == SeatStatus.selected;

    return GestureDetector(
      onTap: () => _onSeatTapped(seat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.transparent),
                color: Colors.transparent,
              ),
              alignment: Alignment.center,
              child: isReservedIcon
                  ? const _ReservedBadge(size: 22)
                  : _SeatGlyph(color: color, size: size.width),
            ),
            if (isSelectedIcon)
              const Positioned.fill(child: Center(child: _SelectedBadge(size: 22))),
            if (seat.status == SeatStatus.available)
              Positioned(
                left: 0,
                right: 0,
                bottom: -8,
                child: Text(
                  seat.column.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kanit(fontSize: 9, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== Price Cards =====
  Widget _priceCardsCompact() {
    const double kCardWidth = 120;
    const double kCardHeight = 96;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          SizedBox(
            width: kCardWidth,
            height: kCardHeight,
            child: _priceCard('Normal', seatPrices['Normal']!, normalRed, border: normalRed),
          ),
          SizedBox(
            width: kCardWidth,
            height: kCardHeight,
            child: _priceCard('Premium', seatPrices['Premium']!, premiumBlue, border: premiumBlue),
          ),
          SizedBox(
            width: kCardWidth,
            height: kCardHeight,
            child: _priceCard('VIP', seatPrices['VIP']!, vipRed, border: vipRed, isSofa: true),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String title, double price, Color iconColor, {Color? border, bool isSofa = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2BB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border ?? Colors.white24, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isSofa ? const _SofaGlyphSmall(color: Colors.red) : Icon(Icons.event_seat, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.kanit(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '฿${price.toStringAsFixed(0)}',
            style: GoogleFonts.kanit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ===== Bottom Bar =====
  Widget _bottomBar() {
    final f = NumberFormat('#,##0');
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A), border: Border(top: BorderSide(color: Colors.white10))),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ที่นั่งที่เลือก', style: GoogleFonts.kanit(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(
                    _selectedSeatIds.isEmpty ? 'ยังไม่ได้เลือก' : _selectedSeatIds.join(', '),
                    style: GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('รวม', style: GoogleFonts.kanit(color: Colors.white70)),
                Text('฿ ${f.format(totalPrice)}',
                    style: GoogleFonts.kanit(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _selectedSeatIds.isEmpty ? null : _onConfirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                disabledBackgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.kanit(fontWeight: FontWeight.w700),
              ),
              child: const Text('ยืนยันการจอง'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== UTILITY =====
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

// ===== Single Seat Glyph =====
class _SeatGlyph extends StatelessWidget {
  const _SeatGlyph({required this.color, this.size = 26});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SeatGlyphPainter(color));
}

class _SeatGlyphPainter extends CustomPainter {
  _SeatGlyphPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..color = color;
    final r = RRect.fromRectAndRadius;

    canvas.drawRRect(r(Rect.fromLTWH(w * 0.18, h * 0.04, w * 0.64, h * 0.38), const Radius.circular(3)), p);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.84, h * 0.24), const Radius.circular(3)), p);
    final legW = w * 0.16, legH = h * 0.20, legTop = h * 0.68 - 1;
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.08, legTop, legW, legH), const Radius.circular(2)), p);
    canvas.drawRRect(r(Rect.fromLTWH(w - legW - w * 0.08, legTop, legW, legH), const Radius.circular(2)), p);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.18, h * 0.86, w * 0.64, h * 0.10), const Radius.circular(2)), p);
  }

  @override
  bool shouldRepaint(_SeatGlyphPainter old) => old.color != color;
}

// ===== VIP Sofa Glyph (แก้บั๊กตามที่คุณแจ้งแล้ว) =====
class _SofaGlyph extends StatelessWidget {
  const _SofaGlyph({
    required this.leftSeat,
    required this.rightSeat,
    required this.colorLeft,
    required this.colorRight,
    required this.onTapLeft,
    required this.onTapRight,
    this.size = 56,
    this.pairHeightOverride,
  });

  final SeatModel leftSeat;
  final SeatModel? rightSeat;
  final Color colorLeft;
  final Color colorRight;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final double size;
  final double? pairHeightOverride;

  @override
  Widget build(BuildContext context) {
    final double pairWidth = size;
    final double pairHeight = pairHeightOverride ?? 30.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final localX = d.localPosition.dx;
        if (localX <= pairWidth / 2) {
          onTapLeft();
        } else {
          onTapRight();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: pairWidth,
              height: pairHeight,
              child: CustomPaint(
                size: Size(pairWidth, pairHeight),
                painter: _SofaGlyphPainter(
                  colorLeft: leftSeat.status == SeatStatus.reserved ? const Color(0xFF5A5A5A) : colorLeft,
                  colorRight: (rightSeat?.status == SeatStatus.reserved) ? const Color(0xFF5A5A5A) : colorRight,
                ),
              ),
            ),
            // Badge ซ้าย
            if (leftSeat.status == SeatStatus.reserved)
              Positioned(left: pairWidth * 0.25 - 11, top: pairHeight / 2 - 11, child: const _ReservedBadge(size: 22))
            else if (leftSeat.status == SeatStatus.selected)
              Positioned(left: pairWidth * 0.25 - 11, top: pairHeight / 2 - 11, child: const _SelectedBadge(size: 22)),
            // Badge ขวา
            if (rightSeat?.status == SeatStatus.reserved)
              Positioned(left: pairWidth * 0.75 - 11, top: pairHeight / 2 - 11, child: const _ReservedBadge(size: 22))
            else if (rightSeat?.status == SeatStatus.selected)
              Positioned(left: pairWidth * 0.75 - 11, top: pairHeight / 2 - 11, child: const _SelectedBadge(size: 22)),
            // หมายเลขที่นั่ง (เฉพาะ available)
            if (leftSeat.status == SeatStatus.available)
              Positioned(
                left: pairWidth * 0.25 - 5, bottom: -6,
                child: Text('${leftSeat.column}', style: GoogleFonts.kanit(fontSize: 9, color: Colors.white70)),
              ),
            if ((rightSeat?.status ?? SeatStatus.available) == SeatStatus.available)
              Positioned(
                left: pairWidth * 0.75 - 5, bottom: -6,
                child: Text('${leftSeat.column + 1}', style: GoogleFonts.kanit(fontSize: 9, color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SofaGlyphPainter extends CustomPainter {
  _SofaGlyphPainter({required this.colorLeft, required this.colorRight});
  final Color colorLeft;
  final Color colorRight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pLeft = Paint()..color = colorLeft;
    final pRight = Paint()..color = colorRight;
    final r = RRect.fromRectAndRadius;

    // พนักพิง
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.03, h * 0.1, w * 0.465, h * 0.3), const Radius.circular(4)), pLeft);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.505, h * 0.1, w * 0.465, h * 0.3), const Radius.circular(4)), pRight);
    // เบาะ
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.01, h * 0.45, w * 0.49, h * 0.45), const Radius.circular(4)), pLeft);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.50, h * 0.45, w * 0.49, h * 0.45), const Radius.circular(4)), pRight);
    // Armrests
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.0, h * 0.25, w * 0.08, h * 0.55), const Radius.circular(2)), pLeft);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.92, h * 0.25, w * 0.08, h * 0.55), const Radius.circular(2)), pRight);
    // Divider
    final pDivider = Paint()..color = Colors.black..strokeWidth = 1.0;
    // ⭐️ แก้บั๊ก: แก้การเรียกใช้ Offset ที่ผิดพลาด
    canvas.drawLine(Offset(w * 0.5, h * 0.45), Offset(w * 0.5, h * 0.9), pDivider);
  }

  @override
  bool shouldRepaint(_SofaGlyphPainter old) => old.colorLeft != colorLeft || old.colorRight != colorRight;
}

// ===== Sofa glyph (small) for Price card =====
class _SofaGlyphSmall extends StatelessWidget {
  const _SofaGlyphSmall({required this.color, this.size = 18});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size * 1.5), painter: _SofaGlyphPainterSmall(color));
}

class _SofaGlyphPainterSmall extends CustomPainter {
  _SofaGlyphPainterSmall(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final r = RRect.fromRectAndRadius;

    canvas.drawRRect(r(Rect.fromLTWH(w * 0.05, h * 0.1, w * 0.9, h * 0.3), const Radius.circular(3)), p);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.02, h * 0.45, w * 0.96, h * 0.35), const Radius.circular(3)), p);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.0, h * 0.25, w * 0.1, h * 0.55), const Radius.circular(2)), p);
    canvas.drawRRect(r(Rect.fromLTWH(w * 0.9, h * 0.25, w * 0.1, h * 0.55), const Radius.circular(2)), p);
    final pFill = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.45, w * 0.04, h * 0.35), pFill);
  }

  @override
  bool shouldRepaint(_SofaGlyphPainterSmall old) => old.color != color;
}

// ===== Reserved / Selected badges =====
class _ReservedBadge extends StatelessWidget {
  const _ReservedBadge({this.size = 16});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBDBDBD), Color(0xFF8D8D8D)],
        ),
        border: Border.all(color: Colors.black54, width: 1),
        boxShadow: const [BoxShadow(blurRadius: 2, offset: Offset(0, 1), color: Colors.black26)],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.person, size: size * 0.68, color: Colors.white),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge({this.size = 16});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber, Colors.amberAccent],
        ),
        border: Border.all(color: Colors.white70, width: 1.0),
        boxShadow: const [BoxShadow(blurRadius: 3, offset: Offset(0, 1), color: Colors.black38)],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.check, size: size * 0.7, color: Colors.white),
    );
  }
}