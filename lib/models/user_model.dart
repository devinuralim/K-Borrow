class UserModel {
  final int id;
  final String idPegawai;
  final String name;
  final String usertype;

  UserModel({
    required this.id,
    required this.idPegawai,
    required this.name,
    required this.usertype,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      idPegawai: json['id_pegawai'],
      name: json['name'],
      usertype: json['usertype'],
    );
  }
}