import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> loadUserInfo() async {
  final prefs = await SharedPreferences.getInstance();

  final name = prefs.getString('name') ?? '사용자';
  final birth = prefs.getString('date') ?? '미입력';
  final gender = prefs.getString('gender') ?? '미입력';

  return [name, birth, gender];
}
