import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'signup_page.dart';
import 'privacy_security_screen.dart';

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
      backgroundColor: const Color(0xFFF9F9F9),
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
                        margin: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Image.asset(
                                'assets/icons/4wk-only.png',
                                height: 64,
                                width: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Welcome Back",
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D1D1F),
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Sign in to continue",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF86868B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Modern, premium login form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
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
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5EA),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5EA),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
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

                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: passwordController,
                              autofillHints: const [AutofillHints.password],
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
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5EA),
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5EA),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
                                ),
                                errorText: _passwordError,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF86868B),
                                    size: 22,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Apple-style sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider with elegant styling
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE5E5EA),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "or continue with",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF86868B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE5E5EA),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social login buttons - clean and modern
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => authController.signInWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E5EA),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          icon: Container(
                            width: 24,
                            height: 24,
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
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => authController.signInWithApple(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E5EA),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.apple,
                            color: Color(0xFF1D1D1F),
                            size: 28,
                          ),
                          label: const Text(
                            "Continue with Apple",
                            style: TextStyle(
                              color: Color(0xFF1D1D1F),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Terms and Privacy
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Text(
                        "By signing in, you agree to our",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF86868B),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const PrivacySecurityScreen());
                            },
                            child: Text(
                              "Terms of Service",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            " and ",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF86868B),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const PrivacySecurityScreen());
                            },
                            child: Text(
                              "Privacy Policy",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom section - minimal and clean
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF86868B),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(() => const SignUpPage());
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    if (_formKey.currentState?.validate() != true) {
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
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        borderColor: Colors.red,
        borderWidth: 1,
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
