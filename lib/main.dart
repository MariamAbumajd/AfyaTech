import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colorspart2.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart' hide AppColors;
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:provider/provider.dart';
import 'backend/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'dart:io'; // For Platform checking

// Global FirebaseMessaging instance
FirebaseMessaging messaging = FirebaseMessaging.instance;

// Firebase Messaging Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp();

  print("Background message handler called!");
  print("Message ID: ${message.messageId}");
  print("Message Data: ${message.data}");
  
  if (message.notification != null) {
    print("Background Notification:");
    print("- Title: ${message.notification?.title}");
    print("- Body: ${message.notification?.body}");
  }

  // Save notification to Firestore in background
  await _saveNotificationToFirestore(message);
}

// Save FCM Token to Firestore (Users collection)
Future<void> _saveFCMTokenToFirestore(String? token, String userId) async {
  if (token != null && token.isNotEmpty && userId.isNotEmpty) {
    try {
      print("Saving FCM token for user: $userId");
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          })
          .then((_) {
            print("✅ FCM token saved successfully for user: $userId");
            print("Token: $token");
          })
          .catchError((error) {
            print("❌ Error saving FCM token: $error");
          });
    } catch (e) {
      print("Exception saving FCM token: $e");
    }
  } else {
    print("Invalid token or user ID. Token: $token, User ID: $userId");
  }
}

// Listen for messages when app is in foreground
void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("=== FOREGROUND MESSAGE RECEIVED ===");
    print("Message ID: ${message.messageId}");
    print("Message Data: ${message.data}");
    
    if (message.notification != null) {
      print("Notification Details:");
      print("- Title: ${message.notification?.title}");
      print("- Body: ${message.notification?.body}");
    }
    
    // Save notification to Firestore
    await _saveNotificationToFirestore(message);
  });
}

// Save notification to Firestore
Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notificationId = FirebaseFirestore.instance.collection('notifications').doc().id;
    
    final notificationData = {
      'id': notificationId,
      'userId': user.uid,
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'general',
      'data': message.data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .set(notificationData);

    print("✅ Notification saved to Firestore: $notificationId");
  } catch (e) {
    print("❌ Error saving notification to Firestore: $e");
  }
}

// Handle when app is opened from terminated state
void _setupMessageOpenedHandler(BuildContext context) {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("=== APP OPENED FROM NOTIFICATION ===");
    print("Message Data: ${message.data}");
    
    // Navigate to specific screen based on message type
    _handleNotificationNavigation(context, message.data);
  });
}

// Handle initial message when app is launched from terminated state
Future<void> _handleInitialMessage(BuildContext context) async {
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print("=== INITIAL MESSAGE FOUND ===");
    print("Message Data: ${initialMessage.data}");
    
    // Navigate based on initial message
    _handleNotificationNavigation(context, initialMessage.data);
  }
}

// Handle navigation based on notification data
void _handleNotificationNavigation(BuildContext context, Map<String, dynamic> data) {
  print("Handling notification navigation with data: $data");
  
  // Example navigation logic based on message type
  final type = data['type']?.toString() ?? '';
  final screen = data['screen']?.toString() ?? '';
  
  print("Notification Type: $type");
  print("Target Screen: $screen");
  
  // Navigate based on notification type
  // Note: You'll need to import and use the actual screen classes
  switch (type) {
    case 'appointment':
      // Navigate to appointments screen
      // Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsScreen()));
      print("Navigate to Appointments Screen");
      break;
    case 'message':
      // Navigate to messages screen
      // Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen()));
      print("Navigate to Messages Screen");
      break;
    case 'reminder':
      // Navigate to reminders screen
      // Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersScreen()));
      print("Navigate to Reminders Screen");
      break;
    default:
      print("Unknown notification type: $type");
      break;
  }
}

// Main Firebase Messaging setup function
Future<void> _setupFirebaseMessaging() async {
  print("Setting up Firebase Messaging...");

  // Request notification permissions (required for iOS)
  if (Platform.isIOS) {
    print("Requesting iOS notification permissions...");
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print("iOS permissions requested");
  } else {
    print("Android platform - permissions handled automatically");
  }

  // Get FCM token
  try {
    String? token = await messaging.getToken();
    print("🔑 FCM Token obtained: $token");
    
    // Get current user ID to save token
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && token != null) {
      print("Current user found: ${currentUser.uid}");
      print("Saving token to Firestore...");
      
      // Save token to Firestore in users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          })
          .then((_) {
            print("✅ FCM token saved to Firestore!");
            print("📁 Collection: users");
            print("📄 Document: ${currentUser.uid}");
            print("🔑 Field: fcmToken");
            print("💾 Value: $token");
          })
          .catchError((error) {
            print("❌ Error saving token to Firestore: $error");
          });
    } else {
      print("⚠️ No authenticated user found or token is null");
      print("User: ${currentUser?.uid}");
      print("Token: $token");
    }
  } catch (e) {
    print("❌ Error getting FCM token: $e");
  }

  // Set up foreground message handler
  _setupForegroundMessageHandler();
  
  print("✅ Firebase Messaging setup complete!");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 Starting AfyaTech App...");

  // 1 — Initialize Firebase
  print("1. Initializing Firebase...");
  await Firebase.initializeApp();
  print("✅ Firebase initialized successfully!");

  // 2 — Initialize Supabase
  print("2. Initializing Supabase...");
  try {
    await Supabase.initialize(
      url: 'https://tayrcbfwemztvrmljaed.supabase.co',
      anonKey: 'sb_publishable_zTaFzUAW5P-WE2CDyE1rfw_VDzt0Oay',
    );
    print("✅ Supabase initialized successfully!");
  } catch (e) {
    print("❌ Supabase initialization error: $e");
  }

  // 3 — Setup Firebase Messaging
  print("3. Setting up Firebase Messaging...");
  try {
    await _setupFirebaseMessaging();
    print("✅ Firebase Messaging setup complete!");
  } catch (e) {
    print("❌ Firebase Messaging setup error: $e");
  }

  // 4 — Set background message handler
  print("4. Setting background message handler...");
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print("✅ Background handler registered!");

  print("🎉 All services initialized successfully!");
  
  runApp(
    MultiProvider(
      providers: [
        // Add Auth Service as Provider
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Add ThemeProvider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Handle initial message when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialMessage(context);
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afya Tech',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
    );
  }

  // Build Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDarkTeal),
        titleTextStyle: TextStyle(
          color: AppColors.textDarkTeal,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergencyRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogBackgroundColor: Colors.white,
      dividerColor: Colors.grey.shade300,
    );
  }

  // Build Dark Theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.darkBackground,
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimaryTeal,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        titleTextStyle: const TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergencyRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogBackgroundColor: AppColors.darkSurface,
      dividerColor: Colors.grey.shade700,
    );
  }
}

// Auth Wrapper to handle user authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Set up message opened handler with context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMessageOpenedHandler(context);
    });
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasError) {
          print('Authentication error: ${snapshot.error}');
          return const ErrorScreen();
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null && user.uid.isNotEmpty) {
            if (user.email != null && user.email!.isNotEmpty) {
              // Save FCM token when user logs in
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  String? token = await messaging.getToken();
                  if (token != null) {
                    await _saveFCMTokenToFirestore(token, user.uid);
                  }
                } catch (e) {
                  print("Error saving FCM token on login: $e");
                }
              });
              
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          }
        }
        
        return const OnboardingScreen();
      },
    );
  }
}

// Splash Screen shown during loading
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.primaryCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'AfyaTech',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDarkMode),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Health, Our Priority',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDarkMode),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              color: AppColors.getPrimary(isDarkMode),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error Screen shown when there's an authentication error
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 50,
                  color: AppColors.emergencyRed,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(isDarkMode),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Unable to connect to our servers. Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondary(isDarkMode),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthWrapper(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDarkMode),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Retry'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Go to Login',
                  style: TextStyle(color: AppColors.getPrimary(isDarkMode)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}