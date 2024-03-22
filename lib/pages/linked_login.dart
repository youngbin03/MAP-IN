import 'package:flutter/material.dart';
import 'package:google_mao/pages/login.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() => runApp(LinkedLogin());

class LinkedLogin extends StatefulWidget {
  @override
  _LinkedLoginState createState() => _LinkedLoginState();
}

class _LinkedLoginState extends State<LinkedLogin> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // 구글 로그인 성공, 필요한 처리를 여기에 추가
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('로그인 성공: ${googleUser.email}'),
            );
          },
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPage()), // LoginPage 위젯 구현 필요
        );
      }
    } catch (error) {
      print('Google 로그인 실패: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0x000002),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Image.asset(
                  'assets/images/earth_login.png', // 큰 사진 이미지 경로 확인 필요
                  fit: BoxFit.cover, // 사진을 화면에 맞게 조정
                ),
              ),
              SizedBox(height: 20),
              SocialLoginButton(
                buttonText: '구글로 로그인하기',
                buttonColor: Colors.white,
                textColor: Colors.black,
                logoPath: 'assets/icons/Google_Logo.png', // 구글 로고 이미지 경로
                onPressed: signInWithGoogle,
              ),
              SocialLoginButton(
                buttonText: '애플로 로그인하기',
                buttonColor: Colors.white,
                textColor: Colors.black,
                logoPath: 'assets/icons/Apple_Logo1.png', // 애플 로고 이미지 경로
                onPressed: signInWithGoogle,
              ),
              SocialLoginButton(
                buttonText: '페이스북으로 로그인하기',
                buttonColor: Colors.white,
                textColor: Colors.black,
                logoPath: 'assets/icons/Facebook_Logo.png', // 페이스북 로고 이미지 경로
                onPressed: signInWithGoogle,
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String buttonText;
  final Color buttonColor;
  final Color textColor;
  final String logoPath;
  final VoidCallback onPressed;

  const SocialLoginButton({
    required this.buttonText,
    required this.buttonColor,
    required this.textColor,
    required this.logoPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 40.0),
      child: ElevatedButton.icon(
        icon: Image.asset(logoPath, height: 20.0),
        label: Text(buttonText, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          primary: buttonColor,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
