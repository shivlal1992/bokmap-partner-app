import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'cart_page.dart';
import 'partner_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // bottom nav index
  String _token = "";
  List<dynamic> _orders = [];
  List<dynamic> _cartOrders = []; // accepted orders
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndOrders();
  }

  Future<void> _loadTokenAndOrders() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token") ?? "";
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);

    final response = await http.get(
      Uri.parse("https://bokmap.com/api/partner/orders"),
      headers: {"Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        _orders = json.decode(response.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptOrder(int id) async {
    final response = await http.post(
      Uri.parse("https://bokmap.com/api/partner/orders/$id/accept"),
      headers: {"Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );

      setState(() {
        _cartOrders.add(data["cart"]);
      });

      _fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to accept order")),
      );
    }
  }

  Future<void> _rejectOrder(int id) async {
    final response = await http.post(
      Uri.parse("https://bokmap.com/api/partner/orders/$id/reject"),
      headers: {"Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
      _fetchOrders();
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  Widget _buildOrdersList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          "No orders available",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order #${order['id']} - ₹${order['total_price']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text("Status: ${order['status']}"),
                Text("Partner Order: ${order['partner_order_status']}"),
                if (order['user'] != null)
                  Text("Customer: ${order['user']['name']}"),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("Accept",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _rejectOrder(order['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text("Reject"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartPage() {
    if (_cartOrders.isEmpty) {
      return const Center(
        child: Text(
          "No accepted orders in cart",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _cartOrders.length,
      itemBuilder: (context, index) {
        final cart = _cartOrders[index];
        final customer = cart["order_details"]["customer"];
        final items = cart["order_details"]["items"] as List<dynamic>;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text("Order #${cart['order_id']} - ₹${cart['total_price']}"),
            subtitle: Text("Customer: ${customer['name']} - ${customer['phone']}"),
            children: [
              for (var item in items)
                ListTile(
                  leading: Image.network(item["image"], width: 40, height: 40),
                  title: Text(item["service"]),
                  subtitle:
                  Text("Qty: ${item["quantity"]} | ₹${item["price"]}"),
                ),
              ListTile(
                title: Text("Payment: ${cart['payment_type']}"),
                subtitle: Text("Date: ${cart['service_date']}"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildOrdersList(), // Home
      const Center(child: Text("Wallet Page (Coming Soon)")),
      const PartnerProfilePage(),
      _buildCartPage(), // Cart
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Partner Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
      ),
    );
  }
}
