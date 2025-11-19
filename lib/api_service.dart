import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://bokmap.com/api";

  // ✅ Register
  static Future<Map<String, dynamic>> register(String phone) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
    return jsonDecode(response.body);
  }

  // ✅ Verify Register OTP
  static Future<Map<String, dynamic>> verifyRegisterOtp(
      String phone,
      String otp,
      String name,
      String email,
      String password,
      String address,
      String role) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone": phone,
        "otp": otp,
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": password,
        "address": address,
        "role": role,
      }),
    );
    final data = jsonDecode(response.body);

    if (data['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data['token']);
    }
    return data;
  }

  // ✅ Login
  static Future<Map<String, dynamic>> login(String phone) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
    return jsonDecode(response.body);
  }

  // ✅ Verify Login OTP
  static Future<Map<String, dynamic>> verifyLoginOtp(
      String phone, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-login-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "otp": otp}),
    );
    final data = jsonDecode(response.body);

    if (data['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data['token']);
    }
    return data;
  }

  // ✅ Get Saved Token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ✅ New method for Partner Profile (Multipart)
  static Future<Map<String, dynamic>> updatePartnerProfileMultipart({
    required Map<String, String> fields,
    required Map<String, File> files,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    var request =
    http.MultipartRequest("POST", Uri.parse("$baseUrl/partner/profile"));

    request.headers.addAll({
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    // Add text fields
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    // Add file fields
    for (var entry in files.entries) {
      request.files
          .add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    return jsonDecode(responseData);
  }
}
