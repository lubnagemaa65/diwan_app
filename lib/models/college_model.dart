class CollegeModel {
  final String id;
  final String name;

  CollegeModel({required this.id, required this.name});

  factory CollegeModel.fromJson(Map<String, dynamic> json) {
    return CollegeModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}
