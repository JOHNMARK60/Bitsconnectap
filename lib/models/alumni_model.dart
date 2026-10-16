class AlumniModel {
  const AlumniModel({required this.profile});

  final Map<String, dynamic> profile;

  factory AlumniModel.fromJson(Map<String, dynamic> json) =>
      AlumniModel(profile: json);
}
