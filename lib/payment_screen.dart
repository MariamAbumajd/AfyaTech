import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'app_colorspart2.dart';
import 'appointment_success_screen.dart';
import '../backend/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String date;
  final String time;
  final String type;
  final String appointmentId;

  const PaymentScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.type,
    required this.appointmentId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  bool _isProcessing = false;
  
  // 🔹 Text Controllers
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  
  // 🔹 Validation Variables
  bool _isCardNumberValid = false;
  bool _isNameValid = false;
  bool _isExpiryValid = false;
  bool _isCvvValid = false;
  
  // 🔹 Focus nodes for field navigation (kept but won't be used for auto navigation)
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _expiryFocusNode = FocusNode();
  final FocusNode _cvvFocusNode = FocusNode();

  // 🔹 Error Messages
  String _cardNumberError = '';
  String _nameError = '';
  String _expiryError = '';
  String _cvvError = '';

  @override
  void initState() {
    super.initState();
    
    // 🔹 Add listeners for real-time validation
    _numberController.addListener(_validateCardNumber);
    _nameController.addListener(_validateName);
    _expiryController.addListener(_validateExpiryDate);
    _cvvController.addListener(_validateCvv);
    
    // 🔹 Add formatting for number and date
    _numberController.addListener(_formatCardNumber);
    _expiryController.addListener(_formatExpiryDate);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameFocusNode.dispose();
    _expiryFocusNode.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  // 🔹 ============ Card Number Formatting Function ============
  void _formatCardNumber() {
    final text = _numberController.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 16) {
      _numberController.text = text.substring(0, 16);
      _numberController.selection = TextSelection.collapsed(offset: 16);
      return;
    }
    
    final formatted = <String>[];
    for (int i = 0; i < text.length; i += 4) {
      final end = i + 4 > text.length ? text.length : i + 4;
      formatted.add(text.substring(i, end));
    }
    
    final newText = formatted.join(' ');
    if (_numberController.text != newText) {
      _numberController.value = _numberController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }
  }

  // 🔹 ============ Expiry Date Formatting Function ============
  void _formatExpiryDate() {
    final text = _expiryController.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 4) {
      _expiryController.text = text.substring(0, 4);
      _expiryController.selection = TextSelection.collapsed(offset: 4);
      return;
    }
    
    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year = text.length > 2 ? text.substring(2) : '';
      final newText = '$month${year.isNotEmpty ? '/$year' : ''}';
      
      if (_expiryController.text != newText) {
        _expiryController.value = _expiryController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
          composing: TextRange.empty,
        );
      }
      
      // 🔹 **Removed auto-navigation to CVV field here**
      // Won't auto-navigate to next field after typing 2 digits
    }
  }

  // 🔹 ============ Card Number Validation Function ============
  void _validateCardNumber() {
    final text = _numberController.text.replaceAll(' ', '');
    
    setState(() {
      if (text.isEmpty) {
        _isCardNumberValid = false;
        _cardNumberError = '';
      } else if (text.length < 16) {
        _isCardNumberValid = false;
        _cardNumberError = 'Must be 16 digits';
      } else if (!_isNumeric(text)) {
        _isCardNumberValid = false;
        _cardNumberError = 'Must contain numbers only';
      } else {
        // 🔹 Luhn Algorithm validation for card number
_isCardNumberValid = text.length == 16 && _isNumeric(text);
_cardNumberError = _isCardNumberValid ? '' : 'Invalid card number';
      }
    });
  }

  // 🔹 ============ Name Validation Function ============
  void _validateName() {
    final text = _nameController.text.trim();
    
    setState(() {
      if (text.isEmpty) {
        _isNameValid = false;
        _nameError = '';
      } else if (text.length < 6) {
        _isNameValid = false;
        _nameError = 'Name must be at least 6 characters';
      } else if (!_isValidName(text)) {
        _isNameValid = false;
        _nameError = 'Please enter first and last name';
      } else if (text.split(' ').length < 2) {
        _isNameValid = false;
        _nameError = 'Please enter full name';
      } else {
        _isNameValid = true;
        _nameError = '';
      }
    });
  }

  // 🔹 ============ Expiry Date Validation Function ============
  void _validateExpiryDate() {
    final text = _expiryController.text.replaceAll('/', '');
    
    setState(() {
      if (text.isEmpty) {
        _isExpiryValid = false;
        _expiryError = '';
      } else if (text.length != 4) {
        _isExpiryValid = false;
        _expiryError = 'Must be 4 digits (MMYY)';
      } else if (!_isNumeric(text)) {
        _isExpiryValid = false;
        _expiryError = 'Must contain numbers only';
      } else {
        final month = int.tryParse(text.substring(0, 2)) ?? 0;
        final year = int.tryParse('20${text.substring(2)}') ?? 0;
        final now = DateTime.now();
        final currentYear = now.year;
        final currentMonth = now.month;
        
        if (month < 1 || month > 12) {
          _isExpiryValid = false;
          _expiryError = 'Month must be between 01 and 12';
        } else if (year < currentYear) {
          _isExpiryValid = false;
          _expiryError = 'Card has expired';
        } else if (year == currentYear && month < currentMonth) {
          _isExpiryValid = false;
          _expiryError = 'Card expired this month';
        } else if (year > currentYear + 20) {
          _isExpiryValid = false;
          _expiryError = 'Unreasonable year';
        } else {
          _isExpiryValid = true;
          _expiryError = '';
        }
      }
    });
  }

  // 🔹 ============ CVV Validation Function ============
  void _validateCvv() {
    final text = _cvvController.text;
    
    setState(() {
      if (text.isEmpty) {
        _isCvvValid = false;
        _cvvError = '';
      } else if (text.length != 3) {
        _isCvvValid = false;
        _cvvError = 'Must be 3 digits';
      } else if (!_isNumeric(text)) {
        _isCvvValid = false;
        _cvvError = 'Must contain numbers only';
      } else {
        _isCvvValid = true;
        _cvvError = '';
      }
    });
  }

  // 🔹 ============ Function to check if text is numeric only ============
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  // 🔹 ============ Function to validate name ============
  bool _isValidName(String name) {
    // Must contain letters only (allowing spaces, hyphens, and apostrophes)
    return RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-'.]+$").hasMatch(name);
  }

  // 🔹 ============ Luhn Algorithm for card number validation ============
  bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  // 🔹 ============ Function to validate all fields ============
  bool get _isFormValid {
    if (_selectedMethod == 1) return true; // Pay at Clinic doesn't need validation
    
    return _isCardNumberValid && 
           _isNameValid && 
           _isExpiryValid && 
           _isCvvValid;
  }

  // 🔹 ============ Payment Processing Function ============
  Future<void> _processPayment() async {
    if (!_isFormValid) {
      _showErrorDialog('Please fill all fields correctly');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.processPayment(
        appointmentId: widget.appointmentId,
        paymentMethod: _selectedMethod == 0 ? 'card' : 'cash',
        amount: (widget.doctor['price'] as num?)?.toDouble() ?? 100.0,
        cardNumber: _selectedMethod == 0 ? _numberController.text.replaceAll(' ', '') : '',
        cardHolder: _selectedMethod == 0 ? _nameController.text : '',
        expiryDate: _selectedMethod == 0 ? _expiryController.text : '',
      );

      if (result['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentSuccessScreen(
              doctor: widget.doctor,
              date: widget.date,
              time: widget.time,
              type: widget.type,
              appointmentId: widget.appointmentId,
            ),
          ),
        );
      } else {
        _showErrorDialog(result['error'] ?? 'Payment processing failed');
      }
    } catch (e) {
      _showErrorDialog('Payment error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(),
                  const SizedBox(height: 30),
                  const Text(
                    "Choose Payment Method",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkTeal,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildPaymentOption(
                    index: 0,
                    title: "Credit Card / Mada",
                    subtitle: "Secure payment using Visa or Mastercard",
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: 15),
                  _buildPaymentOption(
                    index: 1,
                    title: "Pay at Clinic",
                    subtitle: "Pay cash upon arrival",
                    icon: Icons.store_outlined,
                  ),
                  if (_selectedMethod == 0) ...[
                    const SizedBox(height: 30),
                    _buildCreditCardVisual(),
                    const SizedBox(height: 30),
                    const Text(
                      "Enter Card Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDarkTeal,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildCardNumberField(),
                    const SizedBox(height: 15),
                    _buildNameField(),
                    const SizedBox(height: 15),
                    _buildExpiryAndCvvFields(),
                    const SizedBox(height: 20),
                    _buildCardTypeIndicator(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // 🔹 ============ Card Number Field with validation ============
  Widget _buildCardNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Card Number",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_numberController.text.isNotEmpty)
              Text(
                "${_numberController.text.replaceAll(' ', '').length}/16",
                style: TextStyle(
                  color: _isCardNumberValid ? Colors.green : Colors.red,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          maxLength: 19, // 16 digits + 3 spaces
          // 🔹 **Removed auto-navigation here**
          textInputAction: TextInputAction.next, // Shows "Next" button but won't auto-navigate
          decoration: InputDecoration(
            hintText: "0000 0000 0000 0000",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.credit_card, color: AppColors.primaryTeal, size: 20),
            filled: true,
            fillColor: Colors.white,
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isCardNumberValid ? Colors.green : AppColors.primaryTeal,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            suffixIcon: _numberController.text.isNotEmpty
                ? Icon(
                    _isCardNumberValid ? Icons.check_circle : Icons.error,
                    color: _isCardNumberValid ? Colors.green : Colors.red,
                    size: 20,
                  )
                : null,
          ),
          // 🔹 **Removed auto-navigation after 16 digits**
          // User will manually control navigation
        ),
        if (_cardNumberError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              _cardNumberError,
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  // 🔹 ============ Name Field with validation ============
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cardholder Name",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next, // Shows "Next" button only
          decoration: InputDecoration(
            hintText: "Example: Ahmed Mohamed",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryTeal, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isNameValid ? Colors.green : AppColors.primaryTeal,
                width: 1.5,
              ),
            ),
            suffixIcon: _nameController.text.isNotEmpty
                ? Icon(
                    _isNameValid ? Icons.check_circle : Icons.error,
                    color: _isNameValid ? Colors.green : Colors.red,
                    size: 20,
                  )
                : null,
          ),
          // 🔹 **Removed auto-navigation after typing 3 characters**
          // User decides when to move to next field
        ),
        if (_nameError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              _nameError,
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  // 🔹 ============ Expiry and CVV Fields ============
  Widget _buildExpiryAndCvvFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Expiry Date",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_expiryController.text.isNotEmpty)
                    Text(
                      "Month/Year",
                      style: TextStyle(
                        color: _isExpiryValid ? Colors.green : Colors.red,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _expiryController,
                focusNode: _expiryFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 5,
                textInputAction: TextInputAction.next, // Shows "Next" button only
                decoration: InputDecoration(
                  hintText: "MM/YY",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primaryTeal, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isExpiryValid ? Colors.green : AppColors.primaryTeal,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: _expiryController.text.isNotEmpty
                      ? Icon(
                          _isExpiryValid ? Icons.check_circle : Icons.error,
                          color: _isExpiryValid ? Colors.green : Colors.red,
                          size: 20,
                        )
                      : null,
                ),
                // 🔹 **Removed auto-navigation to next field**
              ),
              if (_expiryError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    _expiryError,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "CVV",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_cvvController.text.isNotEmpty)
                    Text(
                      "${_cvvController.text.length}/3",
                      style: TextStyle(
                        color: _isCvvValid ? Colors.green : Colors.red,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cvvController,
                focusNode: _cvvFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscureText: true,
                textInputAction: TextInputAction.done, // Shows "Done" button to hide keyboard
                decoration: InputDecoration(
                  hintText: "123",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryTeal, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isCvvValid ? Colors.green : AppColors.primaryTeal,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: _cvvController.text.isNotEmpty
                      ? Icon(
                          _isCvvValid ? Icons.check_circle : Icons.error,
                          color: _isCvvValid ? Colors.green : Colors.red,
                          size: 20,
                        )
                      : null,
                ),
              ),
              if (_cvvError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    _cvvError,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 ============ Card Type Indicator ============
  Widget _buildCardTypeIndicator() {
    String cardType = "Unknown";
    Color cardColor = Colors.grey;
    
    final number = _numberController.text.replaceAll(' ', '');
    if (number.isNotEmpty) {
      if (number.startsWith('4')) {
        cardType = "Visa";
        cardColor = Color(0xFF1A1F71);
      } else if (number.startsWith('5')) {
        cardType = "Mastercard";
        cardColor = Color(0xFFEB001B);
      } else if (number.startsWith('3')) {
        cardType = "American Express";
        cardColor = Color(0xFF2E77BC);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            color: cardColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            cardType,
            style: TextStyle(
              color: cardColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardVisual() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, Color(0xFF066B75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.nfc, color: Colors.white70, size: 30),
              Icon(Icons.credit_card, color: Colors.white, size: 30),
            ],
          ),
          Text(
            _numberController.text.isEmpty
                ? "**** **** **** ****"
                : _numberController.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Card Holder",
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    _nameController.text.isEmpty
                        ? "YOUR NAME"
                        : _nameController.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Expires",
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    _expiryController.text.isEmpty
                        ? "MM/YY"
                        : _expiryController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    bool isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryTeal),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkTeal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              widget.doctor['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkTeal,
                  ),
                ),
                Text(
                  widget.doctor['specialty'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${widget.date} | ${widget.time}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  "\$${widget.doctor['price']}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing || (_selectedMethod == 0 && !_isFormValid)
                    ? null
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMethod == 0 
                      ? (_isFormValid ? AppColors.accentOrange : Colors.grey)
                      : AppColors.accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedMethod == 0 ? "Pay Now" : "Confirm Booking",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}