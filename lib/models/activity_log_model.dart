class ActivityLogModel {
  final String id;
  final DateTime? timestamp;
  final String userName;
  final String action;

  ActivityLogModel({
    required this.id,
    this.timestamp,
    required this.userName,
    required this.action,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ActivityLogModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
      userName: user is Map ? (user['name'] ?? user['email'] ?? '').toString() : (json['userName'] ?? '').toString(),
      action: (json['action'] ?? json['activity'] ?? '').toString(),
    );
  }
}
