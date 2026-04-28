import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isObscure = true;

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  // Chronic Disease Dropdown
  final List<String> diseases = [
    "None",
    "Diabetes",
    "Hypertension",
    "Heart Disease",
    "Asthma",
    "COPD",
    "Arthritis",
    "Chronic Kidney Disease",
    "Cancer",
    "Hypothyroidism",
    "Obesity",
    "Alzheimer’s",
    "Liver Cirrhosis"
  ];
  String? selectedDisease;

  // Age
  int age = 0;

  // Password validation flags (checklist)
  bool hasUpper = false;
  bool hasLower = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool hasMinLength = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      validatePassword(passwordController.text);
    });
  }

  void validatePassword(String password) {
    setState(() {
      hasUpper = password.contains(RegExp(r'[A-Z]'));
      hasLower = password.contains(RegExp(r'[a-z]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]\\\/]'));
      hasMinLength = password.length >= 8;
    });
  }

  void calculateAge() {
    if (dayController.text.isEmpty || monthController.text.isEmpty || yearController.text.isEmpty) return;
    int d = int.tryParse(dayController.text) ?? 0;
    int m = int.tryParse(monthController.text) ?? 0;
    int y = int.tryParse(yearController.text) ?? 0;
    if (d == 0 || m == 0 || y == 0) return;

    DateTime dob = DateTime(y, m, d);
    DateTime now = DateTime.now();
    int calculatedAge = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) calculatedAge--;
    setState(() {
      age = calculatedAge;
    });
  }

  Future<void> signUpUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirm = confirmPasswordController.text.trim();

    // Basic required fields check (kept as original)
    if (email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        fullNameController.text.trim().isEmpty ||
        dayController.text.isEmpty ||
        monthController.text.isEmpty ||
        yearController.text.isEmpty ||
        selectedDisease == null) {
      showMessage("Please fill all required fields");
      return;
    }

    // Enforce same password rules as checklist
    if (!hasUpper || !hasLower || !hasNumber || !hasSpecial || !hasMinLength) {
      showMessage("Password does not meet requirements");
      return;
    }

    if (password != confirm) {
      showMessage("Passwords do not match");
      return;
    }

    try {
      setState(() => isLoading = true);

      // === Firebase auth: unchanged ===
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      String dob = "${yearController.text.padLeft(4,'0')}-${monthController.text.padLeft(2,'0')}-${dayController.text.padLeft(2,'0')}";

      // Save user data in Firestore (medicalFile left empty; upload later from profile)
      await FirebaseFirestore.instance.collection("Users").doc(uid).set({
        "name": fullNameController.text.trim(),
        "email": email,
        "phone": mobileController.text.trim(),
        "role": "Patient",
        "createdAt": FieldValue.serverTimestamp(),
        "dateOfBirth": dob,
        "age": age,
        "chronicDisease": selectedDisease,
        "hasMedicalCard": false,
        "medicalFile": [],
      });

      showMessage("Account created successfully! 🎉");

      // navigate to login (same as original)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Something went wrong");
    } catch (e) {
      showMessage("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Helper to render checklist row with todo-like square -> check behavior
  Widget _buildCheckRow(String text, bool checked) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: checked ? AppColors.primaryCyan : Colors.transparent,
            border: Border.all(
              color: checked ? AppColors.primaryCyan : Colors.grey.shade400,
              width: 1.3,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: checked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  // keep the old UI exactly: toggle row (Login / Sign Up), fields, same alignment
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // logo
              Image.asset('assets/Logo.jpg', height: 80),
              const SizedBox(height: 10),
              const Text(
                "Afya Tech",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryDarkCyan,
                ),
              ),
              const SizedBox(height: 30),

              // Toggle Buttons (Login / Sign Up) - same as old UI
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryDarkCyan,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
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

              // Form fields (kept identical to old layout)
              _buildLabel("Full Name"),
              _buildTextField(
                controller: fullNameController,
                hint: "Enter your full name",
                icon: Icons.person_outline,
              ),

              _buildLabel("Mobile Number"),
              _buildTextField(
                controller: mobileController,
                hint: "Enter your mobile number",
                icon: Icons.phone_outlined,
              ),

              _buildLabel("Email Address"),
              _buildTextField(
                controller: emailController,
                hint: "Enter your email",
                icon: Icons.email_outlined,
              ),

              _buildLabel("Password"),
              TextField(
                controller: passwordController,
                obscureText: _isObscure,
                onChanged: validatePassword,
                decoration: InputDecoration(
                  hintText: "Create a password",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.secondaryDarkCyan),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.secondaryDarkCyan),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Checklist (todo style) — matches app colors and old UI structure
              _buildCheckRow("At least 1 uppercase letter", hasUpper),
              const SizedBox(height: 8),
              _buildCheckRow("At least 1 lowercase letter", hasLower),
              const SizedBox(height: 8),
              _buildCheckRow("At least 1 number", hasNumber),
              const SizedBox(height: 8),
              _buildCheckRow("At least 1 special character", hasSpecial),
              const SizedBox(height: 8),
              _buildCheckRow("At least 8 characters", hasMinLength),

              const SizedBox(height: 18),

              _buildLabel("Confirm Password"),
              _buildTextField(
                controller: confirmPasswordController,
                hint: "Re-enter your password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 20),

              _buildLabel("Date of Birth (DD/MM/YYYY)"),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: dayController, hint: "DD", icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number, maxLength: 2, onChanged: (_) => calculateAge())),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(controller: monthController, hint: "MM", icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number, maxLength: 2, onChanged: (_) => calculateAge())),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(controller: yearController, hint: "YYYY", icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number, maxLength: 4, onChanged: (_) => calculateAge())),
                ],
              ),

              const SizedBox(height: 10),

              _buildLabel("Age"),
              _buildTextField(
                controller: TextEditingController(text: age.toString()),
                hint: "Age",
                icon: Icons.cake_outlined,
                readOnly: true,
              ),

              const SizedBox(height: 20),

              _buildLabel("Chronic Disease"),
              DropdownButtonFormField<String>(
                value: selectedDisease,
                items: diseases
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: TextStyle(color: AppColors.secondaryDarkCyan)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedDisease = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.secondaryDarkCyan),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: Colors.white,
              ),

              const SizedBox(height: 30),

              // Sign Up button (unchanged behavior)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signUpUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(color: AppColors.secondaryDarkCyan, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.secondaryDarkCyan),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.secondaryDarkCyan)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
