import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mao/pages/find_friends.dart';
import 'package:image_picker/image_picker.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  FocusNode _focusNode1 = FocusNode();
  FocusNode _focusNode2 = FocusNode();
  bool _isTyping = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    // TextEditingController에 리스너 추가
    _focusNode1.addListener(() {
      setState(() {
        // 텍스트 입력 중인지 여부를 감지
        _isTyping = _focusNode1.hasFocus;
      });
    });
    _focusNode2.addListener(() {
      setState(() {
        // 텍스트 입력 중인지 여부를 감지
        _isTyping = _focusNode2.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(0, 5, 40, 0.922),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 30),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _header(context),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24), // 여기에 margin 추가
                    child: _inputField(context),
                  ), // 여기에 margin 추가
                  SizedBox(height: 5), // 간격 조절
                  _forgotPassword(context),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: _bottomWidget(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  File? forileImage;
  Future pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      forileImage = imageTemporary;
      setState(() => forileImage = imageTemporary);
    } on PlatformException catch (e) {
      print('Failed to upload image: $e');
    }
  }

  Widget _header(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        AnimatedSize(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: SizedBox(
            height: _isTyping ? screenHeight * 0.08 : screenHeight * 0.16,
            // Replace YourWidget with the actual content
          ),
        ),
        InkWell(
          onTap: () {
            pickImage(ImageSource.gallery);
          },
          child: forileImage != null
              ? ClipOval(
                  child: Image.file(forileImage!,
                      width: 100, height: 100, fit: BoxFit.cover),
                )
              : Image.asset(
                  'assets/images/avatar-8.png', // 변경하려는 이미지의 경로
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: SizedBox(
            height: _isTyping ? screenHeight * 0.06 : screenHeight * 0.1,
            // Replace YourWidget with the actual content
          ),
        ),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 60,
          child: TextField(
            style: TextStyle(color: Colors.white),
            focusNode: _focusNode1,
            decoration: InputDecoration(
              hintText: "Username",
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.lightBlue[100]?.withOpacity(0.1),
              filled: true,
              prefixIcon: Icon(
                Icons.person,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 60,
          child: TextField(
            style: TextStyle(color: Colors.white),
            focusNode: _focusNode2,
            decoration: InputDecoration(
              hintText: "Password",
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.lightBlue[100]?.withOpacity(0.1),
              filled: true,
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white.withOpacity(0.5),
              ),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            obscureText: !_isPasswordVisible,
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _onLoginButtonPressed(context);
          },
          child: Text(
            "Login",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 8), // 버튼 높이 변경
            primary: Color.fromARGB(255, 63, 108, 206), // #1d2c4d 색상
          ),
        )
      ],
    );
  }

  void _onLoginButtonPressed(BuildContext context) {
    // TODO: 로그인 버튼이 눌렸을 때 실행되는 로직을 추가

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            FindFriends(profileImage: forileImage),
      ),
    );
  }

  _forgotPassword(context) {
    return TextButton(
        onPressed: () {},
        child: Text(
          "Forgot password?",
          style: TextStyle(color: Colors.white),
        ));
  }

  Widget _bottomWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        child: Text(
          "Create new account",
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 63, 108, 206),
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: StadiumBorder(),
          padding: EdgeInsets.symmetric(vertical: 8),
          primary: Colors.transparent,
          side: BorderSide(
            color: Color.fromARGB(255, 63, 108, 206),
          ), // outline 색상을 지정
        ),
      ),
    );
  }
}
