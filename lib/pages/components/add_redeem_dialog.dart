import 'package:flutter/material.dart';
import 'package:flutter_referral_app/pages/home_page.dart';

typedef OnRedeemCodeCallback = void Function(BuildContext context, String code);

class AddRedeemDialog extends StatefulWidget {
  final bool dismissibleWhenSubmitted;
  final OnRedeemCodeCallback callback;

  const AddRedeemDialog({
    super.key,
    this.dismissibleWhenSubmitted = true,
    required this.callback,
  });

  @override
  State<AddRedeemDialog> createState() => _AddRedeemDialogState();

  static Future<T?> show<T>({
    required BuildContext context,
    required OnRedeemCodeCallback callback,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        return AddRedeemDialog(callback: callback);
      },
    );
  }
}

class _AddRedeemDialogState extends State<AddRedeemDialog> {
  final etCode = TextEditingController(text: "MMLH4E");

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text(
              "Enter your referral code",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            EditField(
              controller: etCode,
              hint: "Code",
              centerText: true,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.dismissibleWhenSubmitted) {
                        Navigator.pop(context);
                      }
                      if (etCode.text.isEmpty) return;
                      widget.callback(context, etCode.text);
                    },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
