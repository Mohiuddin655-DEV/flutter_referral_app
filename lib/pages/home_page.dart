import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'see_users.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final etEmail = TextEditingController(text: "mr.x@gmail.com");
  final etName = TextEditingController(text: "Mr. X");
  final etPassword = TextEditingController(text: "123456");
  final etReferralCode = TextEditingController(text: "");
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REFERRAL'),
        centerTitle: true,
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          children: [
            EditField(controller: etName, hint: "Name"),
            EditField(controller: etEmail, hint: "Email"),
            EditField(controller: etPassword, hint: "Password", readOnly: true),
            EditField(controller: etReferralCode, hint: "Refer code"),
            const SizedBox(height: 24),
            SizedBox(
              height: 40,
              child: isLoading
                  ? Container(
                      height: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: !isLoading
                          ? () {
                              setState(() => isLoading = true);
                              UserService.createUser(UserModel(
                                email: etEmail.text,
                                name: etName.text,
                                redeemedCode: etReferralCode.text,
                              )).whenComplete(() {
                                // etEmail.text = "";
                                // etName.text = "";
                                // etPassword.text = "";
                                // etReferralCode.text = "";
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Account created!"),
                                  ),
                                );
                                setState(() => isLoading = false);
                              });
                            }
                          : null,
                      child: const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const SeeAllUsersPage();
                }));
              },
              child: const Text(
                'SEE ALL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool centerText;
  final bool readOnly;

  const EditField({
    super.key,
    required this.controller,
    required this.hint,
    this.centerText = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
        ),
        textAlign: centerText ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
