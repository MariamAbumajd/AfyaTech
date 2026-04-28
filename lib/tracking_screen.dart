import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../app_colorspart2.dart';

class TrackingScreen extends StatefulWidget {
  // جعل المعلمات اختيارية
  final Map<String, dynamic>? doctor;
  final int? queueNumber;
  final String? notificationData; // بيانات إضافية من الإشعارات

  const TrackingScreen({
    super.key,
    this.doctor,
    this.queueNumber,
    this.notificationData,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // === متغيرات الموقع الجديد ===
  Position? _currentPosition;
  String _travelTime = "-- min";
  String _selectedLocation = "Select your location...";
  bool _isGettingLocation = false;

  // === متغيرات الطابور الأصلية ===
  bool isLoading = false;
  int currentlyServing = 10; // قيمة افتراضية
  String distance = "-- km";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // استخدام القيم من الإشعارات إذا وجدت، أو القيم الافتراضية
    final queueNum = widget.queueNumber ?? 15; // قيمة افتراضية
    final doc = widget.doctor ?? {
      'name': 'Dr. Michael Chen',
      'location': 'AfyaTech Center',
      'department': 'General Medicine',
      'rating': 4.8,
      'waitTime': '15 min',
    };
    
    // === VALIDATION: التحقق من منطقية الدور الحالي ===
    if (currentlyServing < 1) currentlyServing = 1;
    if (queueNum > 0 && currentlyServing >= queueNum) {
      currentlyServing = (queueNum - 1).clamp(1, queueNum);
    }

    // === بدء محاكاة الطابور (السيميوليشن) ===
    _startQueueSimulation();
    
    // === جلب الموقع تلقائياً ===
    _getCurrentLocation();
    
    // معالجة بيانات الإشعارات إذا وجدت
    _processNotificationData();
  }
  
  void _processNotificationData() {
    if (widget.notificationData != null && widget.notificationData!.isNotEmpty) {
      print('Notification data received: ${widget.notificationData}');
      // يمكنك معالجة البيانات الإضافية هنا
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // === دالة محاكاة الطابور (السيميوليشن) ===
  void _startQueueSimulation() {
    final queueNum = widget.queueNumber ?? 15;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (currentlyServing < queueNum) {
        setState(() {
          currentlyServing++;
          _updateTravelTimeBasedOnQueue();
        });
      } else {
        timer.cancel();
      }
    });
  }

  // === دالة جلب الموقع ===
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isGettingLocation = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      
      setState(() {
        _currentPosition = position;
        _selectedLocation = "📍 GPS Location";
        _updateTravelTimeBasedOnQueue();
        _isGettingLocation = false;
      });

    } catch (e) {
      print("❌ Location error: $e");
      setState(() {
        _isGettingLocation = false;
        _selectedLocation = "Location error";
      });
    }
  }

  // === تحديث وقت السرح بناءً على الموقع والطابور ===
  void _updateTravelTimeBasedOnQueue() {
    if (_currentPosition == null) {
      _travelTime = "-- min";
      return;
    }

    // حساب الوقت بناءً على عدد الأشخاص المتبقيين + مسافة افتراضية
    final queueNum = widget.queueNumber ?? 15;
    int patientsAhead = (queueNum - currentlyServing).clamp(0, queueNum);
    
    if (patientsAhead <= 0) {
      _travelTime = "Now";
    } else if (patientsAhead <= 2) {
      _travelTime = "~5 min";
    } else if (patientsAhead <= 5) {
      _travelTime = "~10 min";
    } else if (patientsAhead <= 10) {
      _travelTime = "~15 min";
    } else if (patientsAhead <= 20) {
      _travelTime = "~25 min";
    } else {
      _travelTime = "~30+ min";
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Service"),
        content: const Text("Please enable location service to track your queue status"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Permission"),
        content: const Text("AfyaTech needs location permissions to determine your location and estimate arrival time"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // === دالة اختيار الموقع البديلة ===
  void _pickLocation() async {
    String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Pickup Location",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.home, color: AppColors.primaryTeal),
                title: const Text("Home (Downtown)"),
                onTap: () => Navigator.pop(context, "Home"),
              ),
              ListTile(
                leading: const Icon(Icons.work, color: AppColors.primaryTeal),
                title: const Text("Office (Business Bay)"),
                onTap: () => Navigator.pop(context, "Office"),
              ),
              ListTile(
                leading: const Icon(
                  Icons.my_location,
                  color: AppColors.primaryTeal,
                ),
                title: const Text("Current GPS Location"),
                onTap: () => Navigator.pop(context, "GPS"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => isLoading = true);
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        isLoading = false;
        if (selected == "GPS") {
          _getCurrentLocation();
        } else {
          _selectedLocation = selected;
          if (selected == "Home") {
            distance = "3.2 km";
            _travelTime = "15 min";
          } else if (selected == "Office") {
            distance = "8.5 km";
            _travelTime = "25 min";
          }
        }
      });
    }
  }

  void _showCalculationInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textDarkTeal),
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it",
              style: TextStyle(color: AppColors.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueNum = widget.queueNumber ?? 15;
    final doc = widget.doctor ?? {
      'name': 'Dr. Michael Chen',
      'location': 'AfyaTech Center',
      'department': 'General Medicine',
      'rating': 4.8,
      'waitTime': '15 min',
    };

    if (queueNum <= 0) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              Text("Invalid Queue Number: $queueNum"),
            ],
          ),
        ),
      );
    }

    if (isLoading || _isGettingLocation) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          "Live Queue Tracking",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: const Text(
              "JP",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveQueueCard(doc, queueNum),
            const SizedBox(height: 25),
            const Text(
              "Location & Distance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(onTap: _pickLocation, child: _buildMapCard()),
            const SizedBox(height: 25),
            const Text(
              "Smart AI Notifications",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),
            _buildNotificationItem(
              _currentPosition == null
                  ? "Please select your location first"
                  : "Traffic is normal based on your location",
              _currentPosition == null ? Colors.grey : AppColors.accentOrange,
              Icons.traffic,
            ),
            const SizedBox(height: 10),
            _buildNotificationItem(
              "You can leave home now",
              AppColors.primaryCyan,
              Icons.notifications_none,
            ),
            const SizedBox(height: 10),
            _buildNotificationItem(
              "You are next",
              AppColors.primaryTeal,
              Icons.check_circle_outline,
            ),
            const SizedBox(height: 25),
            const Text(
              "How we calculate your time",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),
            _buildCalculationGrid(),
            const SizedBox(height: 30),
            
            // زر تحديث الموقع
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text("Update Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveQueueCard(Map<String, dynamic> doctor, int queueNumber) {
    int patientsAheadCount = (queueNumber - currentlyServing).clamp(0, queueNumber);
    double percentageComplete = 0.0;

    if (queueNumber > 0) {
      percentageComplete = currentlyServing / queueNumber;
      percentageComplete = percentageComplete.clamp(0.0, 1.0);
    }

    int percentageInt = (percentageComplete * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // معلومات الدكتور
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      doctor['name']?.toString().substring(0, 2).toUpperCase() ?? "DC",
                      style: const TextStyle(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name']?.toString() ?? "Doctor",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        doctor['department']?.toString() ?? "Department",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.yellow),
                      const SizedBox(width: 4),
                      Text(
                        doctor['rating']?.toString() ?? "4.8",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.access_time, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                "Your Queue Number",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$queueNumber",
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                "Currently Serving",
                "$currentlyServing",
                Icons.people_outline,
              ),
              _buildInfoColumn(
                "Time to Leave",
                _travelTime,
                Icons.directions_car,
              ),
            ],
          ),
          const SizedBox(height: 25),

          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentageComplete,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$patientsAheadCount patients ahead",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                "$percentageInt% complete",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(200, 50),
                    painter: DottedLinePainter(),
                  ),
                ),
                const Positioned(
                  left: 40,
                  top: 40,
                  child: Icon(Icons.my_location, color: Colors.white, size: 30),
                ),
                const Positioned(
                  right: 40,
                  bottom: 20,
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primaryTeal,
                    size: 30,
                  ),
                ),
                
                if (_currentPosition != null)
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black.withOpacity(0.6),
                      child: Text(
                        "Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, "
                        "Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                
                if (_isGettingLocation)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Getting location...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _currentPosition != null
                      ? AppColors.primaryCyan
                      : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.near_me,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Location",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _selectedLocation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _currentPosition != null
                            ? AppColors.textDarkTeal
                            : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentPosition != null)
                      Text(
                        "Last updated: ${DateTime.now().toString().substring(11, 16)}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Waiting Time",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _travelTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _currentPosition != null
                          ? AppColors.textDarkTeal
                          : Colors.grey,
                    ),
                  ),
                  if (_currentPosition != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _travelTime.contains("Now")
                            ? Colors.green
                            : _travelTime.contains("5 min")
                                ? Colors.orange
                                : AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _travelTime.contains("Now") ? "Ready" : "Estimated",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(
                      Icons.refresh,
                      size: 16,
                    ),
                    label: const Text(
                      "Refresh Location",
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: AppColors.primaryTeal.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _buildGridItem(
          Icons.location_on_outlined,
          "Your current location",
          "We use GPS to find your starting point for accurate estimation.",
        ),
        _buildGridItem(
          Icons.local_hospital_outlined,
          "Clinic location",
          "The destination is fixed based on the doctor's clinic address.",
        ),
        _buildGridItem(
          Icons.speed,
          "Queue movement speed",
          "AI analyzes historical data to predict how fast the queue moves.",
        ),
        _buildGridItem(
          Icons.format_list_numbered,
          "Your queue number",
          "Your position is updated in real-time as patients finish.",
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, String info) {
    return GestureDetector(
      onTap: () => _showCalculationInfo(label, info),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDarkTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryTeal.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    var max = size.width;
    var dashWidth = 5;
    var dashSpace = 5;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}