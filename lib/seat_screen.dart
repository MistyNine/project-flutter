import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:movie_cinema/models/seat_model.dart';

class SeatScreen extends StatefulWidget {
  final String movieTitle;
  final String cinemaName;
  final String screenType;
  final String selectedTime;
  final String selectedDate;
  final Map<String, dynamic> showtimeData;

  const SeatScreen({
    super.key,
    required this.movieTitle,
    required this.cinemaName,
    required this.screenType,
    required this.selectedTime,
    required this.selectedDate,
    required this.showtimeData,
  });

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  // ===============================
  // 📊 State Variables
  // ===============================
  List<RowModel> _seatLayout = [];
  List<String> _selectedSeatIds = [];
  
  // ===============================
  // 🎯 Configuration Constants
  // ===============================
  static const int maxSeatsSelection = 8;
  
  static const Map<String, double> seatPrices = {
    'Normal': 300.0,
    'Premium': 330.0,
    'Couple': 600.0,
  };
  
  static const Map<String, Color> seatColors = {
    'reserved': Color(0xFFD32F2F),      // Red 800
    'selected': Color(0xFF43A047),      // Green 600
    'normal': Color(0xFF333333),        // Dark Grey
    'premium': Color(0xFF1976D2),       // Blue 600
    'couple': Color(0xFF7B1FA2),        // Purple 600
  };

  // Mock seat layout template
  static const List<Map<String, List<Map<String, String>>>> _seatLayoutTemplate = [
    {
      'A': [
        {'status': 'R', 'type': 'Normal'}, {'status': 'A', 'type': 'Normal'}, 
        {'status': 'A', 'type': 'Normal'}, {'status': 'A', 'type': 'Normal'}, 
        {'status': 'AISLE', 'type': 'AISLE'}, {'status': 'AISLE', 'type': 'AISLE'}, 
        {'status': 'A', 'type': 'Normal'}, {'status': 'A', 'type': 'Normal'}, 
        {'status': 'A', 'type': 'Normal'}, {'status': 'R', 'type': 'Normal'}
      ]
    },
    {
      'B': [
        {'status': 'A', 'type': 'Premium'}, {'status': 'A', 'type': 'Premium'}, 
        {'status': 'R', 'type': 'Premium'}, {'status': 'A', 'type': 'Premium'}, 
        {'status': 'AISLE', 'type': 'AISLE'}, {'status': 'AISLE', 'type': 'AISLE'}, 
        {'status': 'A', 'type': 'Premium'}, {'status': 'A', 'type': 'Premium'}, 
        {'status': 'A', 'type': 'Premium'}, {'status': 'A', 'type': 'Premium'}
      ]
    },
    {
      'C': [
        {'status': 'A', 'type': 'Normal'}, {'status': 'A', 'type': 'Normal'}, 
        {'status': 'A', 'type': 'Normal'}, {'status': 'R', 'type': 'Normal'}, 
        {'status': 'AISLE', 'type': 'AISLE'}, {'status': 'AISLE', 'type': 'AISLE'}, 
        {'status': 'A', 'type': 'Normal'}, {'status': 'A', 'type': 'Normal'}, 
        {'status': 'A', 'type': 'Normal'}, {'status': 'A', 'type': 'Normal'}
      ]
    },
    {
      'D': [
        {'status': 'A', 'type': 'Couple'}, {'status': 'A', 'type': 'Couple'}, 
        {'status': 'R', 'type': 'Couple'}, {'status': 'A', 'type': 'Couple'}, 
        {'status': 'AISLE', 'type': 'AISLE'}, {'status': 'AISLE', 'type': 'AISLE'}, 
        {'status': 'A', 'type': 'Couple'}, {'status': 'A', 'type': 'Couple'}, 
        {'status': 'A', 'type': 'Couple'}, {'status': 'A', 'type': 'Couple'}
      ]
    },
  ];

  // ===============================
  // 🔄 Lifecycle Methods
  // ===============================
  @override
  void initState() {
    super.initState();
    _seatLayout = _initializeSeatLayout();
  }

  // ===============================
  // 🏗️ Data Processing Methods
  // ===============================
  List<RowModel> _initializeSeatLayout() {
    final List<RowModel> layout = [];
    
    for (final rowMap in _seatLayoutTemplate) {
      rowMap.forEach((rowName, seatsData) {
        final List<SeatModel> seats = [];
        
        for (int i = 0; i < seatsData.length; i++) {
          final seatData = seatsData[i];
          final seatId = '$rowName${i + 1}';
          
          seats.add(SeatModel(
            id: seatId,
            row: rowName,
            column: i + 1,
            status: _parseSeatStatus(seatData['status']!),
          ));
        }
        
        layout.add(RowModel(rowName: rowName, seats: seats));
      });
    }
    
    return layout;
  }

  SeatStatus _parseSeatStatus(String status) {
    switch (status) {
      case 'R': return SeatStatus.reserved;
      case 'AISLE': return SeatStatus.aisle;
      case 'A':
      default: return SeatStatus.available;
    }
  }

  String _getSeatType(String rowName, int column) {
    for (final templateRow in _seatLayoutTemplate) {
      if (templateRow.containsKey(rowName)) {
        final seatIndex = column - 1;
        if (seatIndex >= 0 && seatIndex < templateRow[rowName]!.length) {
          return templateRow[rowName]![seatIndex]['type'] ?? 'Normal';
        }
      }
    }
    return 'Normal';
  }

  Set<String> _getAvailableSeatTypes() {
    final Set<String> uniqueTypes = {};
    for (final rowMap in _seatLayoutTemplate) {
      rowMap.forEach((_, seatsData) {
        for (final data in seatsData) {
          if (data['type'] != 'AISLE') {
            uniqueTypes.add(data['type'] ?? 'Normal');
          }
        }
      });
    }
    return uniqueTypes;
  }

  // ===============================
  // 💰 Price Calculations
  // ===============================
  double get totalPrice {
    double total = 0.0;
    for (final seatId in _selectedSeatIds) {
      final rowName = seatId.substring(0, 1);
      final column = int.tryParse(seatId.substring(1)) ?? 0;
      final seatType = _getSeatType(rowName, column);
      total += seatPrices[seatType] ?? seatPrices['Normal']!;
    }
    return total;
  }

  // ===============================
  // 🎬 Business Logic Methods
  // ===============================
  void _onSeatTapped(SeatModel seat) {
    if (seat.status == SeatStatus.reserved || seat.status == SeatStatus.aisle) {
      return;
    }

    setState(() {
      final targetRow = _seatLayout.firstWhere((row) => row.rowName == seat.row);
      final targetSeatIndex = targetRow.seats.indexWhere((s) => s.id == seat.id);
      
      if (targetSeatIndex == -1) return;

      final currentSeat = targetRow.seats[targetSeatIndex];

      if (currentSeat.status == SeatStatus.selected) {
        _deselectSeat(currentSeat);
      } else if (currentSeat.status == SeatStatus.available) {
        _selectSeat(currentSeat);
      }
    });
  }

  void _selectSeat(SeatModel seat) {
    if (_selectedSeatIds.length >= maxSeatsSelection) {
      _showMaxSelectionDialog();
      return;
    }

    seat.status = SeatStatus.selected;
    _selectedSeatIds.add(seat.id);
    _selectedSeatIds.sort();
  }

  void _deselectSeat(SeatModel seat) {
    seat.status = SeatStatus.available;
    _selectedSeatIds.remove(seat.id);
  }

  void _onConfirmBooking() {
    if (_selectedSeatIds.isEmpty) return;

    final formatter = NumberFormat('#,##0');
    final message = 'กำลังดำเนินการจองตั๋ว ${_selectedSeatIds.length} ที่นั่ง: '
        '${_selectedSeatIds.join(', ')} รวม ${formatter.format(totalPrice)} บาท';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.kanit()),
        backgroundColor: seatColors['selected'],
      ),
    );
  }

  // ===============================
  // 📱 Dialog Methods
  // ===============================
  void _showMaxSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'จำกัดการเลือกที่นั่ง',
          style: GoogleFonts.kanit(color: Colors.black),
        ),
        content: Text(
          'คุณสามารถเลือกที่นั่งได้สูงสุด $maxSeatsSelection ที่นั่งต่อครั้งเท่านั้น',
          style: GoogleFonts.kanit(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ตกลง',
              style: GoogleFonts.kanit(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🎨 Main Build Method
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildScreenIndicator(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSeatLayout(),
              ),
            ),
          ),
          _buildSeatLegend(),
          const SizedBox(height: 20),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  // ===============================
  // 🏗️ UI Component Methods
  // ===============================
  AppBar _buildAppBar() {
    final movieDetails = widget.showtimeData['details'] ?? 'Action, Animation | 100 นาที';
    final availableTimes = (widget.showtimeData['times'] as List<String>?) ?? 
        ['11:30', '14:00', '16:30', '19:00', '21:30'];

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(Icons.more_vert, color: Colors.white, size: 24),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(160.0),
        child: _buildMovieInfoHeader(movieDetails, availableTimes),
      ),
    );
  }

  Widget _buildMovieInfoHeader(String movieDetails, List<String> availableTimes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movieTitle,
            style: GoogleFonts.kanit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${widget.cinemaName} | ${widget.screenType}',
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
          ),
          Text(
            movieDetails,
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            'ส. ${widget.selectedDate}',
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildTimeSlots(availableTimes),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(List<String> times) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: times.map((time) {
          final isSelected = time == widget.selectedTime;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange.shade700 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.orange.shade700 : Colors.white54,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                time,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            height: 4,
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: const Color(0xFFC0392B),
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAAFF5733),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'หน้าจอ',
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLayout() {
    return Column(
      children: _seatLayout.asMap().entries.map((entry) {
        final rowModel = entry.value;
        return _buildSeatRow(rowModel);
      }).toList(),
    );
  }

  Widget _buildSeatRow(RowModel rowModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRowLabel(rowModel.rowName),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: rowModel.seats.map((seat) => _buildSeatButton(seat)).toList(),
            ),
          ),
          const SizedBox(width: 8),
          _buildRowLabel(rowModel.rowName),
        ],
      ),
    );
  }

  Widget _buildRowLabel(String rowName) {
    return SizedBox(
      width: 25,
      child: Text(
        rowName,
        textAlign: TextAlign.center,
        style: GoogleFonts.kanit(
          color: Colors.white54,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSeatButton(SeatModel seat) {
    if (seat.status == SeatStatus.aisle) {
      return const SizedBox(width: 10);
    }

    final seatType = _getSeatType(seat.row, seat.column);
    final seatColor = _getSeatColor(seat, seatType);
    final seatSize = _getSeatSize(seatType);

    return GestureDetector(
      onTap: () => _onSeatTapped(seat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Container(
          width: seatSize.width,
          height: seatSize.height,
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: seat.status == SeatStatus.available 
                  ? Colors.white24 
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: seat.status == SeatStatus.selected
                ? [BoxShadow(
                    color: Colors.green.shade900,
                    blurRadius: 4,
                    spreadRadius: 0,
                  )]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            seatType == 'Couple' 
                ? '${seat.column}-${seat.column + 1}' 
                : seat.column.toString(),
            style: GoogleFonts.kanit(
              fontSize: seatType == 'Couple' ? 10 : 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeatColor(SeatModel seat, String seatType) {
    switch (seat.status) {
      case SeatStatus.reserved:
        return seatColors['reserved']!;
      case SeatStatus.selected:
        return seatColors['selected']!;
      case SeatStatus.available:
      default:
        switch (seatType) {
          case 'Couple': return seatColors['couple']!;
          case 'Premium': return seatColors['premium']!;
          case 'Normal':
          default: return seatColors['normal']!;
        }
    }
  }

  Size _getSeatSize(String seatType) {
    return Size(
      seatType == 'Couple' ? 60 : 35,
      35,
    );
  }

  Widget _buildSeatLegend() {
    final availableTypes = _getAvailableSeatTypes();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem(seatColors['reserved']!, 'จองแล้ว'),
          _buildLegendItem(seatColors['selected']!, 'เลือกอยู่'),
          
          if (availableTypes.contains('Normal'))
            _buildLegendItem(
              seatColors['normal']!,
              'ปกติ (${seatPrices['Normal']!.toInt()} ฿)',
            ),
          if (availableTypes.contains('Premium'))
            _buildLegendItem(
              seatColors['premium']!,
              'พิเศษ (${seatPrices['Premium']!.toInt()} ฿)',
            ),
          if (availableTypes.contains('Couple'))
            _buildLegendItem(
              seatColors['couple']!,
              'ที่นั่งคู่ (${seatPrices['Couple']!.toInt()} ฿)',
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildBottomSummary() {
    final formatter = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildSelectedSeatsInfo()),
            const SizedBox(width: 16),
            _buildPriceInfo(formatter),
            const SizedBox(width: 16),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSeatsInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ที่นั่งที่เลือก',
          style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedSeatIds.isEmpty ? 'ยังไม่ได้เลือก' : _selectedSeatIds.join(', '),
          style: GoogleFonts.kanit(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'รวม',
          style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
        ),
        Text(
          '฿ ${formatter.format(totalPrice)}',
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.yellow.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _selectedSeatIds.isEmpty ? null : _onConfirmBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        disabledBackgroundColor: Colors.grey.shade800,
      ),
      child: Text(
        'ยืนยันการจอง',
        style: GoogleFonts.kanit(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}