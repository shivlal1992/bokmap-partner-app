import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerProfilePage extends StatefulWidget {
  const PartnerProfilePage({super.key});

  @override
  State<PartnerProfilePage> createState() => _PartnerProfilePageState();
}

class _PartnerProfilePageState extends State<PartnerProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token == null) return;

    final response = await http.get(
      Uri.parse("https://bokmap.com/api/partner/profile"),
      headers: {"Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _profile = data["data"];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
  }

  String _fullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return "https://bokmap.com/storage/$path";
  }

  Future<void> _openInBrowser(String? path) async {
    final url = _fullUrl(path);
    if (url.isEmpty) return;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open $url")),
      );
    }
  }

  Widget _buildInfoRow(String label, String? value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: Colors.blueGrey),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value ?? "-"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(
          body: Center(child: Text("No profile found")));
    }

    final user = _profile!["user_app"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Partner Profile"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _profile!["photo"] != null
                        ? NetworkImage(_fullUrl(_profile!["photo"]))
                        : null,
                    backgroundColor: Colors.blue.shade100,
                    child: _profile!["photo"] == null
                        ? const Icon(Icons.person,
                        size: 50, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?["name"] ?? "No Name",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user?["email"] ?? "",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personal Info
            _buildSection("Personal Info", Icons.person, [
              _buildInfoRow("Phone", user?["phone"], icon: Icons.phone),
              _buildInfoRow("Address", user?["address"], icon: Icons.home),
              _buildInfoRow("Role", user?["role"], icon: Icons.badge),
            ]),

            // Partner Details
            _buildSection("Partner Details", Icons.business_center, [
              _buildInfoRow("Vehicle Type", _profile!["vehicle_type"],
                  icon: Icons.directions_car),
              _buildInfoRow("Vehicle Number", _profile!["vehicle_number"],
                  icon: Icons.confirmation_number),
              _buildInfoRow("Bank Account", _profile!["bank_account_number"],
                  icon: Icons.account_balance),
              _buildInfoRow("IFSC Code", _profile!["ifsc_code"],
                  icon: Icons.code),
              _buildInfoRow("Bank Name", _profile!["bank_name"],
                  icon: Icons.account_balance_wallet),
              _buildInfoRow("Verification Status",
                  _profile!["verification_status"],
                  icon: Icons.verified_user),
              if (_profile!["rejection_reason"] != null)
                _buildInfoRow("Rejection Reason",
                    _profile!["rejection_reason"], icon: Icons.warning),
            ]),

            // Documents
            // _buildSection("Documents", Icons.description, [
            //   if (_profile!["aadhaar_card"] != null)
            //     ListTile(
            //       leading: const Icon(Icons.credit_card, color: Colors.blue),
            //       title: const Text("Aadhaar Card"),
            //       subtitle: Text(_profile!["aadhaar_card"]),
            //       trailing: const Icon(Icons.open_in_new),
            //       onTap: () => _openInBrowser(_profile!["aadhaar_card"]),
            //     ),
            //   if (_profile!["driving_license"] != null)
            //     ListTile(
            //       leading:
            //       const Icon(Icons.drive_eta, color: Colors.deepOrange),
            //       title: const Text("Driving License"),
            //       subtitle: Text(_profile!["driving_license"]),
            //       trailing: const Icon(Icons.open_in_new),
            //       onTap: () => _openInBrowser(_profile!["driving_license"]),
            //     ),
            // ]),
          ],
        ),
      ),
    );
  }
}
