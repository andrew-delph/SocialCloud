// Package imports:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

// Project imports:
import '../routes/app_pages.dart';

class AuthService extends GetxService {
  Rx<User?> user = Rx(null);

  @override
  onInit() {
    super.onInit();
    FirebaseAuth.instance.userChanges().listen((changeUser) {
      user(changeUser);
    });
  }

  Future<String> getToken() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (token == null) {
      signOut();
      throw "Authentication Error";
    }
    // return kReleaseMode ? token : "k6_auth_admin";
    return token;
  }

  bool isAuthenticated() {
    return user() != null;
  }

  signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  User getUser() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      signOut();
      throw "Authentication Error";
    }

    return currentUser;
  }

  void deleteUser() {
    User user = getUser();
    user.delete();
  }
}
