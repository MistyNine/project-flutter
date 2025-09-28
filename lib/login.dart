import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_cinema/home_screen.dart'; 
import 'authentication.dart'; 
import 'register.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthenticationService _authService = AuthenticationService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.kanit()),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        _showMessage('เข้าสู่ระบบสำเร็จ');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        _showMessage('อีเมลหรือรหัสผ่านไม่ถูกต้อง', isError: true);
      }
    } catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      if (e.toString().contains('ไม่พบผู้ใช้')) {
        errorMessage = 'ไม่พบบัญชีผู้ใช้นี้';
      } else if (e.toString().contains('รหัสผ่าน')) {
        errorMessage = 'รหัสผ่านไม่ถูกต้อง';
      } else if (e.toString().toLowerCase().contains('network')) {
        errorMessage = 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      }
      _showMessage(errorMessage, isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. พื้นหลัง: รูปภาพเต็มจอพร้อมโอเวอร์เลย์สีดำ
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/imageprofile.jpg"), // <<< รูปพื้นหลังที่คุณต้องการใช้
                fit: BoxFit.cover,
                // ใส่ฟิลเตอร์สีดำเพื่อให้อ่านง่ายขึ้น
                colorFilter: ColorFilter.mode(
                  Color(0x99000000), 
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // หัวข้อ
                        Text(
                          'ลงชื่อเข้าใช้',
                          style: GoogleFonts.kanit(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'รับชมภาพยนต์อะไรใหม่ๆได้ที่นี้ 💗',
                          style: GoogleFonts.kanit(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),

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
                        const SizedBox(height: 16),

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
                            if (v.length < 6) return 'รหัสผ่านสั้นเกินไป';
                            return null;
                          },
                        ),

                        // โค้ดส่วนนี้ถูกลบออกไปแล้ว
                        // const SizedBox(height: 12),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.end,
                        //   children: [
                        //     Text(
                        //       'ลืมรหัสผ่าน?',
                        //       style: GoogleFonts.kanit(
                        //         color: Colors.white60,
                        //         fontSize: 13,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        
                        const SizedBox(height: 24), // เพิ่มระยะห่างให้เท่ากับก่อนหน้า

                        // ปุ่มเข้าสู่ระบบ (Gradient)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [Colors.grey.shade700, Colors.grey]
                                      : const [Color.fromARGB(255, 255, 17, 0), Color.fromARGB(255, 255, 67, 67)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'เข้าสู่ระบบ',
                                        style: GoogleFonts.kanit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color.fromARGB(255, 245, 244, 244),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        _divider('ยังไม่มีบัญชี?'),
                        const SizedBox(height: 16),

                        // ปุ่มสมัครสมาชิก
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.person_add_alt_1,
                                size: 18, color: Colors.white),
                            label: Text(
                              'สมัครสมาชิก',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(.28),
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

  // ===== Widgets ย่อย =====

  Widget _divider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: GoogleFonts.kanit(color: Colors.white60, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

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
      borderSide: BorderSide(color: Colors.white.withOpacity(.18), width: 1.2),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF6A4A), width: 1.6),
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
        fillColor: Colors.white.withOpacity(0.08), 
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
}