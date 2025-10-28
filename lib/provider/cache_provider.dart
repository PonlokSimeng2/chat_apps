import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cache_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharePref(Ref ref) {
  throw UnimplementedError();
}