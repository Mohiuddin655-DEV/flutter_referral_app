import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef OnRedeemCodeCallback = void Function(BuildContext context, String code);

class RedeemDialog extends StatefulWidget {
  final bool dismissibleWhenSubmitted;
  final OnRedeemCodeCallback callback;

  const RedeemDialog({
    super.key,
    this.dismissibleWhenSubmitted = true,
    required this.callback,
  });

  @override
  State<RedeemDialog> createState() => _RedeemDialogState();

  static Future<T?> show<T>({
    required BuildContext context,
    required OnRedeemCodeCallback callback,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) {
        return RedeemDialog(callback: callback);
      },
    );
  }
}

class _RedeemDialogState extends State<RedeemDialog> {
  final etCode = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Apply redeem code"),
      content: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
          ),
          child: TextField(
            controller: etCode,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "CODE",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ),
      actions: [
        Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
              child: const Text(
                "CANCEL",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              if (widget.dismissibleWhenSubmitted) {
                Navigator.pop(context);
              }
              if (etCode.text.isEmpty) return;
              widget.callback(context, etCode.text);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
              child: const Text(
                "SUBMIT",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
      /*content: Container(
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
      ),*/
    );
  }
}
