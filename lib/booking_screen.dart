import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🔹 إضافة Provider
import 'app_colorspart2.dart';
import 'payment_screen.dart';
import 'backend/auth_service.dart'; // 🔹 إضافة Auth Service

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _appointmentType = 'In-Clinic';
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  // القائمة التي تحمل الأيام
  List<DateTime> _days = [];

  // 🔹 متغيرات جديدة للـ Firebase
  bool _isLoading = false;
  String _loadingMessage = '';

  // دالة لتوليد الأيام بناءً على تاريخ بداية معين
  void _generateDays(DateTime startDate) {
    _days = List.generate(14, (index) => startDate.add(Duration(days: index)));
  }

  @override
  void initState() {
    super.initState();
    // عند فتح الصفحة لأول مرة، نولد الأيام بدءاً من اليوم الحالي
    _generateDays(DateTime.now());
  }

  // ============ دالة فتح الـ Date Picker ============
  Future<void> _selectDateFromPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _days[0], // التاريخ المبدئي هو أول يوم في القائمة الحالية
      firstDate: DateTime.now(), // لا يمكن اختيار تاريخ قديم
      lastDate: DateTime.now().add(const Duration(days: 365)), // متاح لمدة سنة
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal, // لون التقويم
              onPrimary: Colors.white,
              onSurface: AppColors.textDarkTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // عند اختيار تاريخ جديد، نعيد توليد الشريط الأفقي ليبدأ منه
        _generateDays(picked);
        _selectedDateIndex = 0; // نختار أول يوم أوتوماتيكياً
        _selectedTimeIndex = -1; // تصفير الوقت المختار
      });
    }
  }
  // ==================================================

  final List<String> _timeSlots = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '1:00 PM',
    '1:30 PM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
  ];

  // 🔹 ============ دالة الحجز مع Firebase ============
  Future<void> _bookAppointment() async {
    try {
      // جلب الـ AuthService من Provider
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // التحقق من تسجيل الدخول
      if (authService.currentUser == null) {
        _showErrorDialog('Please login to book an appointment');
        return;
      }

      // التحقق من اختيار الوقت
      if (_selectedTimeIndex == -1) {
        _showErrorDialog('Please select a time slot');
        return;
      }

      setState(() {
        _isLoading = true;
        _loadingMessage = 'Booking your appointment...';
      });

      // تحضير البيانات
      final selectedDateObj = _days[_selectedDateIndex];
      final formattedDate = DateFormat('EEEE, MMM d, y').format(selectedDateObj);
      final selectedTime = _timeSlots[_selectedTimeIndex];
      
      // 🔹 الحجز في Firebase
      final result = await authService.bookAppointment(
      
doctorId: widget.doctor['doctorId']?.toString() ?? 
          widget.doctor['id']?.toString() ?? 
          'doc_001',
        doctorName: widget.doctor['name'],
        doctorSpecialty: widget.doctor['specialty'] ?? widget.doctor['specialization'] ?? 'General',
        appointmentType: _appointmentType,
        date: formattedDate,
        time: selectedTime,
        price: (widget.doctor['price'] as num?)?.toDouble() ?? 100.0,
        clinicLocation: widget.doctor['location'] ?? widget.doctor['clinic'] ?? 'City Center',
        notes: '',
        symptoms: '',
      );

      if (result['success'] == true) {
        // 🔹 النجاح - الانتقال لصفحة الدفع
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              doctor: widget.doctor,
              date: formattedDate,
              time: selectedTime,
              type: _appointmentType,
              appointmentId: result['appointmentId'], // 🔹 تمرير appointmentId
            ),
          ),
        );
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to book appointment');
      }
    } catch (e) {
      print('Booking error: $e');
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  // 🔹 دالة لعرض رسالة خطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Error'),
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
    // 🔹 عرض loading إذا كان في حالة تحميل
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryTeal,
              ),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                style: const TextStyle(
                  color: AppColors.textDarkTeal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_days.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    DateTime selectedDateObj = _days[_selectedDateIndex];
    String formattedSelectedDate = DateFormat(
      'EEEE, MMM d, y',
    ).format(selectedDateObj);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Book Appointment",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Appointment Type",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    title: "In-Clinic Visit",
                    icon: Icons.apartment,
                    isSelected: _appointmentType == 'In-Clinic',
                    onTap: () => setState(() => _appointmentType = 'In-Clinic'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTypeCard(
                    title: "Online Consultation",
                    icon: Icons.videocam_outlined,
                    isSelected: _appointmentType == 'Online',
                    onTap: () => setState(() => _appointmentType = 'Online'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ============ تعديل الجزء الخاص بالتاريخ (Header + Combobox) ============
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkTeal,
                  ),
                ),

                // زر الـ Combobox / Date Picker
                GestureDetector(
                  onTap: _selectDateFromPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.textDarkTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'MMM dd',
                          ).format(_days[0]), // يظهر تاريخ بداية القائمة
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDarkTeal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textDarkTeal,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // =====================================================================
            const SizedBox(height: 15),

            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  return _buildDateCard(index);
                },
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Available Time",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_timeSlots.length, (index) {
                return _buildTimeChip(index);
              }),
            ),

            const SizedBox(height: 30),

            const Text(
              "Booking Summary",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),
            _buildSummaryCard(formattedSelectedDate),

            const SizedBox(height: 30),

            // 🔹 ============ تعديل زر التأكيد ============
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedTimeIndex == -1 || _isLoading
                    ? null // لو مفيش وقت مختار أو في حالة تحميل، الزرار يقفل
                    : () async {
                        await _bookAppointment(); // 🔹 استدعاء دالة الحجز مع Firebase
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Proceed to Payment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4DBFD8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: [
            if (!isSelected)
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textDarkTeal,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDarkTeal,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(int index) {
    bool isSelected = _selectedDateIndex == index;
    DateTime date = _days[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedDateIndex = index),
      child: Container(
        width: 65,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDarkTeal,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(int index) {
    bool isSelected = _selectedTimeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeIndex = index),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            _timeSlots[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String dateText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
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
                    widget.doctor['specialty'] ?? widget.doctor['specialization'] ?? 'General',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.location_on_outlined,
            widget.doctor['location'] ?? widget.doctor['clinic'] ?? "City Center",
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.medical_services_outlined, _appointmentType),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.calendar_today_outlined, dateText),
          const SizedBox(height: 12),
          _buildSummaryRow(
            Icons.access_time,
            _selectedTimeIndex == -1
                ? "Select Time"
                : _timeSlots[_selectedTimeIndex],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Consultation Fee",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Text(
                "\$${widget.doctor['price']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}