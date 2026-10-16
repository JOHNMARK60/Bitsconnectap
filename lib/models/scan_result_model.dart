class ScanResultModel {
  const ScanResultModel({
    required this.message,
    this.status,
    this.studentName,
    this.eventName,
    this.scanTime,
  });

  final String message;
  final String? status;
  final String? studentName;
  final String? eventName;
  final String? scanTime;

  factory ScanResultModel.fromResponse(Map<String, dynamic> response) {
    final data = Map<String, dynamic>.from(
      response['data'] is Map ? response['data'] as Map : {},
    );
    return ScanResultModel(
      message: response['message']?.toString() ?? 'Scan processed.',
      status: data['status']?.toString(),
      studentName: data['student_name']?.toString(),
      eventName: data['event_name']?.toString(),
      scanTime: data['scan_time']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'message': message,
    'status': status,
    'student_name': studentName,
    'event_name': eventName,
    'scan_time': scanTime,
  };
}
