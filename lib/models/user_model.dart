class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastSignIn;

  UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastSignIn,
  });

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastSignIn: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastSignIn': lastSignIn.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      createdAt: DateTime.parse(json['createdAt']),
      lastSignIn: DateTime.parse(json['lastSignIn']),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, phoneNumber: $phoneNumber, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}