import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Email/Şifre ile Giriş
  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email ve şifre gerekli!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      _goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Bir hata oluştu. Tekrar deneyin.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Google ile Giriş
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Önceki oturumu temizle
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _goToHome();
    } catch (e) {
      setState(() {
        _errorMessage = 'Google ile giriş başarısız. Lütfen tekrar deneyin.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu email ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      case 'email-already-in-use':
        return 'Bu email zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'invalid-email':
        return 'Geçersiz email adresi.';
      case 'invalid-credential':
        return 'Email veya şifre hatalı.';
      default:
        return 'Bir hata oluştu. Tekrar deneyin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // 3D Logo Area
                  _build3DLogo(),
                  const SizedBox(height: 40),

                  // Tab Selector
                  _buildTabSelector(),
                  const SizedBox(height: 28),

                  // Form Fields
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],

                  const SizedBox(height: 28),

                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 24),

                  // Divider
                  _buildDivider(),
                  const SizedBox(height: 24),

                  // Google Button
                  _buildGoogleButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DLogo() {
    return Column(
      children: [
        // 3D Logo Container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid pattern
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 9,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      index < 5 ? '${index + 1}' : '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3D Title
        Stack(
          children: [
            // Shadow layer
            Transform.translate(
              offset: const Offset(3, 3),
              child: Text(
                'SUDOKU CLASH',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            // Main text with gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
              ).createShader(bounds),
              child: const Text(
                'SUDOKU CLASH',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Beyinlerin Savaşı',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Giriş Yap', true)),
          Expanded(child: _buildTab('Kayıt Ol', false)),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isLoginTab) {
    final isSelected = _isLogin == isLoginTab;
    return GestureDetector(
      onTap: () => setState(() => _isLogin = isLoginTab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Email adresiniz',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Şifreniz',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.lock_outlined, color: Colors.white.withOpacity(0.7)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.7),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                _isLogin ? 'GİRİŞ YAP' : 'KAYIT OL',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata,
                size: 28,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google ile Giriş',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
