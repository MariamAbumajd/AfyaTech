import 'package:afyatech/home_screen.dart' show HomeScreen; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  
  // إضافة الـ controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // دالة لعرض مسدجات محسنة بدون زر OK
  void _showCustomSnackBar(BuildContext context, String message, {bool isError = false}) {
    // الحصول على ألوان النظام الحالية
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // إخفاء أي مسدج حالياً قبل عرض الجديد
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // إظهار المسدج الجديد بدون زر OK
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError 
                ? colorScheme.onError 
                : colorScheme.onInverseSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError 
            ? colorScheme.error 
            : colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        duration: const Duration(seconds: 3), // تختفي تلقائياً بعد 3 ثواني
        margin: const EdgeInsets.all(16),
        // تم إزالة action: SnackBarAction لإزالة زر OK
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على ألوان النظام
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Image.asset('assets/Logo.jpg', height: 100),
              const SizedBox(height: 20),

              Text(
                "Afya Tech",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode 
                      ? colorScheme.primary 
                      : AppColors.secondaryDarkCyan,
                ),
              ),
              Text(
                "Your Health, Our Priority",
                style: TextStyle(
                  fontSize: 14, 
                  color: isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey
                ),
              ),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? colorScheme.surfaceVariant : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? colorScheme.primary : AppColors.secondaryDarkCyan,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: isDarkMode ? colorScheme.onPrimary : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // الحقول بعد إضافة controllers
              _buildTextField(
                hint: "Enter email or mobile number",
                icon: Icons.email_outlined,
                controller: emailController,
                colorScheme: colorScheme,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              _buildTextField(
                hint: "Enter your password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
                colorScheme: colorScheme,
                isDarkMode: isDarkMode,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    // إرسال الإيميل للنسيان
                    if (emailController.text.trim().isEmpty) {
                      _showCustomSnackBar(context, "Please enter your email first", isError: true);
                      return;
                    }

                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: emailController.text.trim(),
                      );

                      _showCustomSnackBar(context, "Password reset email sent successfully! Please check your inbox.");
                    } on FirebaseAuthException catch (e) {
                      String errorMessage;
                      switch (e.code) {
                        case 'invalid-email':
                          errorMessage = "Invalid email address format.";
                          break;
                        case 'user-not-found':
                          errorMessage = "No account found with this email.";
                          break;
                        default:
                          errorMessage = "Error sending reset email: ${e.message}";
                      }
                      _showCustomSnackBar(context, errorMessage, isError: true);
                    } catch (e) {
                      _showCustomSnackBar(context, "An unexpected error occurred. Please try again.", isError: true);
                    }
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: isDarkMode ? colorScheme.primary : AppColors.secondaryDarkCyan
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    // التحقق من الحقول الفارغة
                    if (emailController.text.trim().isEmpty) {
                      _showCustomSnackBar(context, "Please enter your email", isError: true);
                      return;
                    }
                    
                    if (passwordController.text.trim().isEmpty) {
                      _showCustomSnackBar(context, "Please enter your password", isError: true);
                      return;
                    }

                    // كود تسجيل الدخول باستخدام Firebase
                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      _showCustomSnackBar(context, "Login successful! Welcome back.");
                      
                      // الانتقال للصفحة الرئيسية بعد تأخير بسيط
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      });
                    } on FirebaseAuthException catch (e) {
                      String errorMessage;
                      switch (e.code) {
                        case 'invalid-email':
                          errorMessage = "Invalid email address format.";
                          break;
                        case 'user-disabled':
                          errorMessage = "This account has been disabled.";
                          break;
                        case 'user-not-found':
                          errorMessage = "No account found with this email.";
                          break;
                        case 'wrong-password':
                          errorMessage = "Incorrect password. Please try again.";
                          break;
                        default:
                          errorMessage = "Login failed: ${e.message}";
                      }
                      _showCustomSnackBar(context, errorMessage, isError: true);
                    } catch (e) {
                      _showCustomSnackBar(context, "An unexpected error occurred. Please try again.", isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? colorScheme.primary : AppColors.secondaryDarkCyan,
                    foregroundColor: isDarkMode ? colorScheme.onPrimary : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                    shadowColor: isDarkMode ? Colors.black38 : Colors.grey.withOpacity(0.5),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة محسنة لبناء الحقول النصية
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    required ColorScheme colorScheme,
    required bool isDarkMode,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      style: TextStyle(
        color: isDarkMode ? colorScheme.onSurface : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey,
          fontSize: 14
        ),
        prefixIcon: Icon(
          icon, 
          color: isDarkMode ? colorScheme.primary : AppColors.secondaryDarkCyan
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                  color: isDarkMode ? colorScheme.onSurfaceVariant : Colors.grey,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.outline : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.outlineVariant : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.primary : AppColors.secondaryDarkCyan,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? colorScheme.surfaceVariant : Colors.white,
      ),
    );
  }
}