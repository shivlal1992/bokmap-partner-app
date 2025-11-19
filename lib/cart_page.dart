import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import other pages
import 'home_page.dart';
import 'partner_profile_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _token = "";
  List<dynamic> _cartOrders = [];
  bool _loading = true;
  int _selectedIndex = 2; // Cart tab index

  @override
  void initState() {
    super.initState();
    _loadCartOrders();
  }

  Future<void> _loadCartOrders() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token") ?? "";

    final response = await http.get(
      Uri.parse("https://bokmap.com/api/partner/carts"),
      headers: {"Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        _cartOrders = json.decode(response.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // =======================
  // FETCH ESTIMATE FOR ORDER
  // =======================
  Future<List<dynamic>> fetchEstimate(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    final response = await http.get(
      Uri.parse("https://bokmap.com/api/orders/$orderId/estimate"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // =======================
  // SEND ESTIMATE
  // =======================
  Future<bool> sendEstimate(int orderId, String serviceName, int price,
      int cleaning, List<Map<String, dynamic>> parts) async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    final response = await http.post(
      Uri.parse("https://bokmap.com/api/partner/orders/$orderId/estimate"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "service_name": serviceName,
        "service_price": price,
        "cleaning_charge": cleaning,
        "parts": parts,
      }),
    );

    return response.statusCode == 200;
  }

  // =======================
  // SEND FINAL BILL
  // =======================
  Future<bool> sendFinalBill(int billId, int price, int cleaning,
      List<Map<String, dynamic>> parts) async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    final response = await http.post(
      Uri.parse("https://bokmap.com/api/estimate/$billId/final"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "service_price": price,
        "cleaning_charge": cleaning,
        "parts": parts,
      }),
    );

    return response.statusCode == 200;
  }

  // =======================
  // OPEN ESTIMATE FORM
  // =======================
  void _openEstimateForm(int orderId) {
    TextEditingController service = TextEditingController();
    TextEditingController price = TextEditingController();
    TextEditingController cleaning = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Estimate"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: service, decoration: const InputDecoration(labelText: "Service Name")),
            TextField(controller: price, decoration: const InputDecoration(labelText: "Service Price")),
            TextField(controller: cleaning, decoration: const InputDecoration(labelText: "Cleaning Charge")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool ok = await sendEstimate(
                  orderId, service.text, int.parse(price.text), int.parse(cleaning.text), []);
              if (ok) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // =======================
  // OPEN FINAL BILL FORM
  // =======================
  void _openFinalBillForm(int billId) {
    TextEditingController price = TextEditingController();
    TextEditingController cleaning = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Final Bill"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: price, decoration: const InputDecoration(labelText: "Final Price")),
            TextField(controller: cleaning, decoration: const InputDecoration(labelText: "Cleaning Charge")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              bool ok = await sendFinalBill(
                  billId, int.parse(price.text), int.parse(cleaning.text), []);
              if (ok) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Send Final"),
          ),
        ],
      ),
    );
  }

  // =======================
  // MARK AS DELIVERED
  // =======================
  Future<void> _markAsDelivered(int orderId) async {
    final url = Uri.parse("https://bokmap.com/api/partner/orders/$orderId/deliver");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer _token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order delivered successfully")),
      );
      _loadCartOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.statusCode}")),
      );
    }
  }

  // =======================
  // UI BUILD
  // =======================
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_cartOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Cart")),
        body: const Center(child: Text("Cart is empty", style: TextStyle(fontSize: 20, color: Colors.red))),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Order Cart")),
      body: ListView.builder(
        itemCount: _cartOrders.length,
        itemBuilder: (context, index) {
          final cart = _cartOrders[index];
          final orderDetails = cart["order_details"] ?? {};
          final items = orderDetails["items"] ?? [];
          final customer = orderDetails["customer"] ?? {};
          final isDelivered = (cart['partner_order_status'] == 'delivered');

          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text("Order #${cart['order_id']} • ₹${cart['total_price']}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text("${customer['name'] ?? ''}"),
                  const SizedBox(width: 10),
                  const Icon(Icons.phone, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text("${customer['phone'] ?? ''}"),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer['email'] != null) Text("📧 ${customer['email']}"),
                      if (customer['address'] != null) Text("📍 ${customer['address']}"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text("Payment: ${cart['payment_type']}", style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.teal,
                          ),
                          Chip(
                            label: Text("Status: ${cart['partner_order_status']}",
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: isDelivered ? Colors.green : Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // SHOW ITEMS
                for (var item in items)
                  ListTile(
                    leading: item["image"] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item["image"], width: 50, height: 50, fit: BoxFit.cover),
                    )
                        : const Icon(Icons.image_not_supported, size: 40),
                    title: Text(item["service"] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                    Text("Qty: ${item["quantity"] ?? 0} • ₹${item["price"] ?? 0}"),
                  ),

                // ======================================
                // 🚀  ESTIMATE + FINAL BILL UI (ADDED)
                // ======================================
                FutureBuilder(
                  future: fetchEstimate(cart['order_id']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final estimates = snapshot.data!;
                    if (estimates.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () => _openEstimateForm(cart['order_id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text("Send Estimate"),
                        ),
                      );
                    }

                    final bill = estimates.first;
                    bool estimateAccepted = bill["status"] == "accepted";
                    bool isFinalBill = bill["status"] == "final";
                    bool finalAccepted = bill["final_status"] == "accepted";
                    bool finalRejected = bill["final_status"] == "rejected";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Estimate Bill", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),

                        ListTile(
                          title: Text(bill["service_name"]),
                          subtitle: Text("Estimate Total: ₹${bill['estimated_total']}"),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Chip(
                            label: Text("Status: ${bill['status']}"),
                            backgroundColor: bill['status'] == "pending"
                                ? Colors.orange
                                : bill['status'] == "accepted"
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),

                        if (estimateAccepted && !isFinalBill)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              onPressed: () => _openFinalBillForm(bill['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              child: const Text("Send Final Bill"),
                            ),
                          ),

                        if (isFinalBill)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text("Final Bill", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ),

                              ListTile(
                                title: Text(bill["service_name"]),
                                subtitle: Text("Final Amount: ₹${bill['estimated_total']}"),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Chip(
                                  label: Text("Customer: ${bill['final_status']}"),
                                  backgroundColor: finalAccepted
                                      ? Colors.green
                                      : finalRejected
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),

                // MARK AS DELIVERED
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isDelivered ? Colors.green : Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(isDelivered ? Icons.check_circle : Icons.local_shipping, color: Colors.white),
                    label: Text(isDelivered ? "Delivered" : "Mark as Delivered",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: isDelivered
                        ? null
                        : () => _markAsDelivered(cart['order_id']),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
    if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PartnerProfilePage()));
    }
  }
}
