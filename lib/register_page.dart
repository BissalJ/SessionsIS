import 'package:flutter/material.dart';
import 'package:fingerprint_auth_app/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String _passwordErrorText = '';
  String _emailErrorText = '';

  // Password requirements
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  Future<void> _registerProfessor() async {
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final school = _schoolController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty || school.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields are required')),
        );
        return;
      }

      // Validate email format and professor requirement
      if (!_validateEmail(email)) {
        return;
      }

      // Validate password strength
      if (!_validatePassword(password)) {
        return;
      }

      setState(() => _loading = true);

      final authService = AuthService();
      final result = await authService.registerProfessor(
        email: email,
        password: password,
        name: name,
        school: school,
        role: 'admin', // Auto-fill role as admin
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful. Please log in.')),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: ${e.toString()}')),
      );
    }
  }

  bool _validateEmail(String email) {
    // Standard email regex with additional check for professor email
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');

    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailErrorText = 'Please enter a valid email address');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    if (!email.toLowerCase().contains('prof')) {
      setState(() => _emailErrorText = 'Professor email must contain "prof"');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professor email must contain "prof"')),
      );
      return false;
    }

    setState(() => _emailErrorText = '');
    return true;
  }

  bool _validatePassword(String password) {
    // Reset error
    setState(() => _passwordErrorText = '');

    // Check all requirements
    _hasMinLength = password.length >= 8;
    _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    _hasLowerCase = password.contains(RegExp(r'[a-z]'));
    _hasNumber = password.contains(RegExp(r'[0-9]'));
    _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!_hasMinLength ||
        !_hasUpperCase ||
        !_hasLowerCase ||
        !_hasNumber ||
        !_hasSpecialChar) {
      setState(
          () => _passwordErrorText = 'Password does not meet requirements');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password does not meet all requirements')),
      );
      return false;
    }

    return true;
  }

  void _onPasswordChanged(String password) {
    // Update password requirements in real-time
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool obscure = false,
      TextInputType? keyboardType,
      int? maxLength,
      String? errorText,
      Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF395075),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        errorText: errorText?.isNotEmpty == true ? errorText : null,
        errorStyle: const TextStyle(color: Colors.orange),
        counterText: '',
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password must contain:',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _hasMinLength ? Icons.check_circle : Icons.error,
              color: _hasMinLength ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '8+ characters',
              style: TextStyle(
                color: _hasMinLength ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              _hasUpperCase ? Icons.check_circle : Icons.error,
              color: _hasUpperCase ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '1 uppercase letter',
              style: TextStyle(
                color: _hasUpperCase ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              _hasLowerCase ? Icons.check_circle : Icons.error,
              color: _hasLowerCase ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '1 lowercase letter',
              style: TextStyle(
                color: _hasLowerCase ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              _hasNumber ? Icons.check_circle : Icons.error,
              color: _hasNumber ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '1 number',
              style: TextStyle(
                color: _hasNumber ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              _hasSpecialChar ? Icons.check_circle : Icons.error,
              color: _hasSpecialChar ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '1 special character',
              style: TextStyle(
                color: _hasSpecialChar ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E5D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E5D),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Register Professor Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(
                  _emailController,
                  'Email (must contain "prof")',
                  Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailErrorText,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  'Password',
                  Icons.lock,
                  obscure: _obscurePassword,
                  errorText: _passwordErrorText,
                  onChanged: _onPasswordChanged,
                ),
                const SizedBox(height: 8),
                // Toggle password visibility
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    child: Text(
                      _obscurePassword ? 'Show Password' : 'Hide Password',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildTextField(
                  _schoolController,
                  'School/Department',
                  Icons.school,
                ),
                _buildPasswordRequirements(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _registerProfessor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CA6D1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register Professor',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _schoolController.dispose();
    super.dispose();
  }
}
