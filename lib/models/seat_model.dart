// lib/models/seat_model.dart

/// สถานะของที่นั่งแต่ละประเภท
enum SeatStatus {
  available, // ว่าง (พร้อมให้เลือก)
  reserved,  // ถูกจองแล้ว (เลือกไม่ได้)
  selected,  // ถูกเลือกโดยผู้ใช้
  aisle,     // ทางเดิน (ไม่ใช่ที่นั่ง)
}

/// Model สำหรับที่นั่งแต่ละตัว
class SeatModel {
  final String id; // เช่น 'A1', 'B5'
  final String row;
  final int column;
  SeatStatus status; 

  SeatModel({
    required this.id,
    required this.row,
    required this.column,
    required this.status,
  });
}

/// Model สำหรับการจัดกลุ่มที่นั่งเป็นแถว
class RowModel {
  final String rowName; // เช่น 'A', 'B'
  final List<SeatModel> seats;

  RowModel({
    required this.rowName,
    required this.seats,
  });
}