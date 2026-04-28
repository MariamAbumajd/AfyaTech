import 'package:flutter/material.dart';
import 'package:afyatech/app_colorspart2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyWalletScreen extends StatefulWidget {
  final double initialBalance;
  final Function(double) onBalanceUpdated;
  
  const MyWalletScreen({
    super.key,
    required this.initialBalance,
    required this.onBalanceUpdated,
  });

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  double _balance = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  bool _isBalanceHidden = false;
  bool _isCardHidden = true;

  // Sample card data
  final String cardNumber = "4582 1596 3574 8521";
  final String cardHolder = "JANE DOE";
  final String expiryDate = "09/28";

  @override
  void initState() {
    super.initState();
    _balance = widget.initialBalance;
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load balance from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final balance = data['walletBalance'];
          setState(() {
            _balance = (balance != null ? balance.toDouble() : 0.0);
          });
        }
        
        // Load transactions
        await _loadTransactions(user.uid);
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      setState(() {
        _transactions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _addFunds(double amount) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        
        final newBalance = _balance + amount;
        final transactionId = _firestore.collection('wallet_transactions').doc().id;
        final timestamp = DateTime.now();
        
        // Create transaction record
        final transactionData = {
          'id': transactionId,
          'userId': user.uid,
          'type': 'top_up',
          'amount': amount,
          'balanceBefore': _balance,
          'balanceAfter': newBalance,
          'description': 'Wallet Top Up',
          'timestamp': timestamp,
          'date': timestamp.toIso8601String(),
          'status': 'completed',
        };
        
        // Update user balance in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Save transaction to Firestore
        await _firestore.collection('wallet_transactions').doc(transactionId).set(transactionData);
        
        // Update local state
        setState(() {
          _balance = newBalance;
          _transactions.insert(0, transactionData);
        });
        
        // Call callback function
        widget.onBalanceUpdated(newBalance);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added \$${amount.toStringAsFixed(2)} to your wallet'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding funds: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _transferFunds(double amount, String recipientEmail) async {
    // Implementation for transferring funds
    // This is a simplified version - you'll need to implement actual logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('Transfer functionality will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showScanCardDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 60,
                  color: AppColors.primaryTeal,
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    color: AppColors.accentOrange,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Scanning Card...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Position your card within the frame to capture details automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Simulate scanning after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isCardHidden = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Card Scanned & Verified!"),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showTopUpDialog() {
    double amount = 0.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add Funds"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter amount to add to your wallet:"),
                const SizedBox(height: 20),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: "\$ ",
                    labelText: "Amount",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    amount = double.tryParse(value) ?? 0.0;
                  },
                ),
                const SizedBox(height: 20),
                const Text("Quick Add:"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [50, 100, 200, 500].map((value) {
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          amount = value.toDouble();
                        });
                      },
                      child: Text('\$$value'),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (amount > 0) {
                    Navigator.pop(context);
                    _addFunds(amount);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a valid amount"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Add Funds"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryTeal),
              const SizedBox(height: 20),
              Text(
                'Loading wallet...',
                style: TextStyle(
                  color: AppColors.textDarkTeal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "My Wallet",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDarkTeal),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textDarkTeal),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credit Card
            Container(
              width: double.infinity,
              height: 220,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0A8E9C),
                    Color(0xFF4DBFD8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Balance",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isBalanceHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _isBalanceHidden = !_isBalanceHidden;
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    _isBalanceHidden ? "\$ ••••••" : "\$${_balance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isCardHidden
                                ? "**** **** **** ${cardNumber.substring(15)}"
                                : cardNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const Icon(Icons.credit_card, color: Colors.white54),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cardHolder,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            expiryDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(child: _buildActionButton(Icons.add, "Top Up", _showTopUpDialog)),
                const SizedBox(width: 15),
                Expanded(child: _buildActionButton(Icons.arrow_upward, "Transfer", () => _transferFunds(50, ""))),
                const SizedBox(width: 15),
                Expanded(child: _buildActionButton(Icons.qr_code_scanner, "Scan Card", _showScanCardDialog)),
              ],
            ),
            const SizedBox(height: 30),

            // Recent Transactions
            const Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),

            if (_transactions.isEmpty)
              _buildEmptyTransactions()
            else
              ..._transactions.map((transaction) => _buildTransactionItem(transaction)).toList(),

            // Add some sample transactions if no real transactions exist
            if (_transactions.isEmpty) ...[
              _buildTransactionItem({
                'description': 'Dr. Sarah Consultation',
                'date': 'Nov 15, 2025',
                'amount': -50.00,
                'type': 'payment',
              }),
              _buildTransactionItem({
                'description': 'Wallet Top Up',
                'date': 'Nov 10, 2025',
                'amount': 200.00,
                'type': 'top_up',
              }),
              _buildTransactionItem({
                'description': 'Pharmacy Purchase',
                'date': 'Oct 28, 2025',
                'amount': -30.50,
                'type': 'payment',
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final description = transaction['description'] ?? 'Transaction';
    final date = transaction['date'] ?? 'Unknown date';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final type = transaction['type'] ?? 'unknown';
    
    final isIncome = amount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            isIncome ? "+ \$${amount.toStringAsFixed(2)}" : "- \$${(-amount).toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : AppColors.textDark,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            "No transactions yet",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your transactions will appear here",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}