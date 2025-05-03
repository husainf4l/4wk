import 'package:get/get.dart';

class NavigationController extends GetxController {
  // Observable value to track the current tab index
  final RxInt currentIndex = 0.obs;

  // Method to change the current tab
  void changeTab(int index) {
    currentIndex.value = index;
  }
}
