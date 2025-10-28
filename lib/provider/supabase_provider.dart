import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'supabase_provider.g.dart';

const String supabaseUrl = "https://pwicnpzqmeesgdncewkt.supabase.co";
const String _anonKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3aWNucHpxbWVlc2dkbmNld2t0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzMTI4NjksImV4cCI6MjA2Nzg4ODg2OX0.-I-wf7gMQSEvT9eVrC_QvrJOWPoRtTZa4MBuWlUq3HM";
Future<void> initSupabase() async {
  try {
    await Supabase.initialize(anonKey: _anonKey, url: supabaseUrl);
  } catch (e) {
    log('error initializing supabase', error: e);
  }
}

@Riverpod(keepAlive: true)
Supabase supabase(Ref ref) {
  return Supabase.instance;
}
