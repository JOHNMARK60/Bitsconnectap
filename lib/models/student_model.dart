class StudentModel {
  const StudentModel({required this.profile});

  final Map<String, dynamic> profile;

  factory StudentModel.fromJson(Map<String, dynamic> json) =>
      StudentModel(profile: json);
}
