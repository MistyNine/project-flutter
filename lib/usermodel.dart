class UserModel {
  final String id;
  final String email;
  final String photopath;

  UserModel({
    required this.id,
    required this.email,
    required this.photopath,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      photopath: data['profile'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'photopath': photopath,
    };
  }
}