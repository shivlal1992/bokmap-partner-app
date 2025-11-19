import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'home_page.dart';

class CompletePartnerProfilePage extends StatefulWidget {
  final VoidCallback? onProfileCompleted;

  const CompletePartnerProfilePage({Key? key, this.onProfileCompleted})
      : super(key: key);

  @override
  _CompletePartnerProfilePageState createState() =>
      _CompletePartnerProfilePageState();
}

class _CompletePartnerProfilePageState
    extends State<CompletePartnerProfilePage> {
  final vehicleController = TextEditingController();
  final numberController = TextEditingController();
  final bankAccountController = TextEditingController();
  final bankController = TextEditingController();
  final ifscController = TextEditingController();

  File? photoFile;
  File? aadhaarFile;
  File? licenseFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFile(Function(File) onPicked) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      onPicked(File(picked.path));
    }
  }

  void saveProfile() async {
    var res = await ApiService.updatePartnerProfileMultipart(
      fields: {
        "vehicle_type": vehicleController.text,
        "vehicle_number": numberController.text,
        "bank_account_number": bankAccountController.text,
        "bank_name": bankController.text,
        "ifsc_code": ifscController.text,
      },
      files: {
        if (photoFile != null) "photo": photoFile!,
        if (aadhaarFile != null) "aadhaar_card": aadhaarFile!,
        if (licenseFile != null) "driving_license": licenseFile!,
      },
    );

    if (res['success'] == true ||
        (res['message']?.toString().contains("profile") ?? false)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile submitted successfully!")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Failed to update profile")),
      );
    }
  }

  Widget _buildTextField(
      {required String label,
        required TextEditingController controller,
        IconData? icon,
        TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildUploadTile(
      {required String label,
        required IconData icon,
        File? file,
        required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        trailing: file != null
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.upload_file, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Partner Profile"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Form Fields
            _buildTextField(
                label: "Vehicle Type",
                controller: vehicleController,
                icon: Icons.directions_car),
            _buildTextField(
                label: "Vehicle Number",
                controller: numberController,
                icon: Icons.confirmation_number),
            _buildTextField(
                label: "Bank Account Number",
                controller: bankAccountController,
                icon: Icons.account_balance,
                type: TextInputType.number),
            _buildTextField(
                label: "Bank Name",
                controller: bankController,
                icon: Icons.account_balance_wallet),
            _buildTextField(
                label: "IFSC Code",
                controller: ifscController,
                icon: Icons.code),

            const SizedBox(height: 20),

            // Upload Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Upload Documents",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            _buildUploadTile(
              label: "Profile Photo",
              icon: Icons.person,
              file: photoFile,
              onTap: () => pickFile((file) => setState(() => photoFile = file)),
            ),
            _buildUploadTile(
              label: "Aadhaar Card",
              icon: Icons.credit_card,
              file: aadhaarFile,
              onTap: () =>
                  pickFile((file) => setState(() => aadhaarFile = file)),
            ),
            _buildUploadTile(
              label: "Driving License",
              icon: Icons.drive_eta,
              file: licenseFile,
              onTap: () =>
                  pickFile((file) => setState(() => licenseFile = file)),
            ),

            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blue,
                ),
                onPressed: saveProfile,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("Submit Profile",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
