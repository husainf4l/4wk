import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Apple-style branding - clean and minimal
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/icons/4wk-only.png',
                                height: 64,
                                width: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Welcome",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D1D1F),
                                letterSpacing: -0.8,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Sign in to continue",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF86868B),
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Modern, premium login form
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFF2F2F7),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 0,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email field
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    controller: emailController,
                                    autofillHints: const [AutofillHints.email],
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1D1D1F),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Email",
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: Color(0xFF86868B),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 0,
                                          ),
                                      errorText: _emailError,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}",
                                      ).hasMatch(value)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) {
                                      setState(() => _emailError = null);
                                    },
                                  ),
                                ),

                                // Password field
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    controller: passwordController,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1D1D1F),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                        color: Color(0xFF86868B),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 0,
                                          ),
                                      errorText: _passwordError,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: const Color(0xFF86868B),
                                          size: 20,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _obscurePassword =
                                                      !_obscurePassword,
                                            ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) {
                                      setState(() => _passwordError = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Apple-style sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _signIn(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider with elegant styling
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 0.5,
                              color: const Color(0xFFE5E5EA),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "or",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF86868B),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 0.5,
                              color: const Color(0xFFE5E5EA),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Social login buttons - clean and modern
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => authController.signInWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E5EA),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          icon: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          label: const Text(
                            "Continue with Google",
                            style: TextStyle(
                              color: Color(0xFF1D1D1F),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => authController.signInWithApple(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E5EA),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.apple,
                            color: Color(0xFF1D1D1F),
                            size: 20,
                          ),
                          label: const Text(
                            "Continue with Apple",
                            style: TextStyle(
                              color: Color(0xFF1D1D1F),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom section - minimal and clean
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF86868B),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to sign up
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      await authController.signIn(
        emailController.text.trim(),
        passwordController.text,
      );
    } catch (e) {
      Get.snackbar(
        "Sign In Failed",
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
