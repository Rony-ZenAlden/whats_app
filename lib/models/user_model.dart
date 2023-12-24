class UserModel {
  String uid;
  String name;
  String email;
  String password;
  String image;

  UserModel(
      this.uid,
      this.name,
      this.email,
      this.password,
      {this.image = "",}
      );

  Map<String, dynamic> toJson()
  {
    return {
      'uid': uid,
      'name':name,
      'email':email,
      'password':password,
      'image':image,
    };
  }
}
