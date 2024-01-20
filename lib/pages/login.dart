import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mao/pages/find_friends.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mao/create_image.dart';

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
  String image = "";
  TextEditingController textController = TextEditingController();
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MAPING",
                          style: TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        Text(
                          "에 오신것을 환영합니다",
                          style: TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "🌎🤩🌈",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 22),
                    child: _inputField(context),
                  ), // 여기에 margin 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _header('assets/images/avatar-8.png', '남성'),
                        _header('assets/images/avatar-6.png', '여성'),
                        _header('assets/images/avatar-1.png', '기타'),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, 36, 24, 4), // 여기에 margin 추가
                    child: _login(context),
                  ),
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

  Widget _header(String imageUrl, String jender) {
    return Column(
      children: [
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
                  imageUrl, // 변경하려는 이미지의 경로
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
        ),
        Text(
          jender,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        // AnimatedSize(
        //   duration: Duration(milliseconds: 500),
        //   curve: Curves.easeInOut,
        //   child: SizedBox(
        //     height: _isTyping ? screenHeight * 0.06 : screenHeight * 0.1,
        //     // Replace YourWidget with the actual content
        //   ),
        // ),
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
            controller: textController,
            style: TextStyle(color: Colors.white),
            focusNode: _focusNode1,
            decoration: InputDecoration(
              hintText: "  닉네임을 입력하세요",
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.lightBlue[100]?.withOpacity(0.1),
              filled: true,
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  _login(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            _onLoginButtonPressed(context);
          },
          child: Text(
            "바로 로그인",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 10), // 버튼 높이 변경
            primary: Color.fromARGB(191, 28, 57, 121), // #1d2c4d 색상
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
        onPressed: () async {
          image = await createImage.generateImage(textController.text);
        },
        child: Text(
          "아바타를 클릭하여 프로필을 생성하세요.",
          style: TextStyle(color: Colors.white, fontSize: 12),
        ));
  }

  Widget _bottomWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton(
        onPressed: () {},
        child: Image.asset(
          'assets/icons/arrow_back_white.png',
          color: Colors.white,
          width: 24.0, // 원하는 폭으로 조정
          height: 24.0, // 원하는 높이로 조정
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          primary: Color.fromARGB(115, 46, 112, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
    );
  }
}
