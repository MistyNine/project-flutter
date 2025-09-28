import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'authentication.dart';
import 'package:movie_cinema/home_screen.dart'; // Import HomeScreen for navigation after success

// กำหนดสีหลักของธีม (Deep Crimson Red - คล้ายกับแอปสตรีมมิ่งทั่วไป)
const Color _kPrimaryAccent = Color(0xFFE50914); 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ลบ Controller สำหรับชื่อผู้ใช้ (Username) ออก
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AuthenticationService _authService = AuthenticationService();

  @override
  void dispose() {
    // ลบ dispose ของ _usernameController ออก
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.kanit()), // Use Kanit font
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('รหัสผ่านไม่ตรงกัน', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ใช้แค่ email และ password ในการลงทะเบียน
      bool success = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text, 
      );

      if (success) {
        _showMessage('สมัครสมาชิกสำเร็จ! กำลังนำทางไปหน้าหลัก...');
        if (mounted) {
          // Navigate to HomeScreen after successful registration
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        _showMessage('สมัครสมาชิกไม่สำเร็จ', isError: true);
      }
    } catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาดในการสมัครสมาชิก';
      // Specific error handling based on Firebase errors (e.g., weak password, email already in use)
      if (e.toString().contains('already-in-use')) {
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      } else if (e.toString().toLowerCase().contains('network')) {
        errorMessage = 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      }
      _showMessage(errorMessage, isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // Helper Widget: TextField (Matching Login Screen Style)
  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? trailing,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(.15), width: 1.0),
    );

    // สีเส้นกรอบเมื่อ Focus ถูกปรับเป็นสีแดงเข้ม (Accent Color)
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kPrimaryAccent, width: 2.0), 
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscure,
      style: GoogleFonts.kanit(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.kanit(color: Colors.white70),
        hintText: hint,
        hintStyle: GoogleFonts.kanit(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05), 
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: trailing,
        enabledBorder: baseBorder,
        focusedBorder: focusedBorder,
        errorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: focusedBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // Helper Widget: Divider (Matching Login Screen Style)
  Widget _divider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: GoogleFonts.kanit(color: Colors.white54, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // พื้นหลังหลักเป็นสีดำสนิท
      backgroundColor: Colors.black,
      appBar: AppBar(
        // AppBar ใสและใช้สีดำเหมือนเดิม
        backgroundColor: Colors.black.withOpacity(0.8), 
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'สร้างบัญชีใหม่', 
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. พื้นหลัง: รูปภาพเต็มจอพร้อมโอเวอร์เลย์สีดำเข้ม
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/imageprofile.jpg"), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color(0xC0000000), // Dark overlay
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // 2. เนื้อหาหลัก: Form อยู่ตรงกลาง
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35), 
                  decoration: BoxDecoration(
                    // พื้นหลัง Form ใช้สีดำโปร่งใสเข้มเพื่อให้กลืนกับพื้นหลัง
                    color: Colors.black.withOpacity(0.85), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // หัวข้อ
                        Text(
                          'สมัครสมาชิก', 
                          style: GoogleFonts.kanit(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white, 
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'เริ่มต้นการเดินทางสู่โลกภาพยนตร์', 
                          style: GoogleFonts.kanit(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 35),
                        
                        // ฟิลด์ชื่อผู้ใช้ถูกลบออกแล้ว

                        // อีเมล
                        _textField(
                          controller: _emailController,
                          label: 'อีเมล',
                          hint: 'you@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                            if (!v.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // รหัสผ่าน
                        _textField(
                          controller: _passwordController,
                          label: 'รหัสผ่าน',
                          hint: 'อย่างน้อย 6 ตัวอักษร',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          trailing: IconButton(
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white60,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                            if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        
                        // ยืนยันรหัสผ่าน
                        _textField(
                          controller: _confirmPasswordController,
                          label: 'ยืนยันรหัสผ่าน',
                          hint: 'กรอกรหัสผ่านซ้ำอีกครั้ง',
                          icon: Icons.vpn_key_outlined,
                          obscure: _obscureConfirmPassword,
                          trailing: IconButton(
                            onPressed: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white60,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                            if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                            return null;
                          },
                        ),

                        const SizedBox(height: 30), 

                        // ปุ่มสมัครสมาชิก (Solid สีแดง)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: _kPrimaryAccent, 
                              shadowColor: _kPrimaryAccent.withOpacity(0.6),
                              elevation: 10,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white, 
                                        strokeWidth: 3,
                                      ),
                                    )
                                : Text(
                                      'สมัครสมาชิก',
                                      style: GoogleFonts.kanit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white, 
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        _divider('มีบัญชีอยู่แล้ว?'), 
                        const SizedBox(height: 20),

                        // ปุ่มกลับไปหน้าเข้าสู่ระบบ (Outline สีขาว)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                      // ใช้ Navigator.pop(context) เพื่อย้อนกลับไปหน้า Login
                                      Navigator.pop(context);
                                    },
                            icon: const Icon(Icons.login,
                                size: 18, color: Colors.white70), // ไอคอนสีขาวเทา
                            label: Text(
                              'เข้าสู่ระบบ',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white, 
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(.28), // ขอบสีขาวเทาบางๆ
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
