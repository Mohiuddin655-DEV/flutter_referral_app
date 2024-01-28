import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Dialogs extends StatefulWidget {
  final String? title;
  final TextStyle? titleStyle;
  final String? message;
  final TextStyle? messageStyle;
  final DialogType type;

  const Dialogs.alert({
    super.key,
    this.title,
    this.titleStyle,
    this.message,
    this.messageStyle,
  }) : type = DialogType.alert;

  const Dialogs.editor({
    super.key,
    this.title,
    this.titleStyle,
    this.message,
    this.messageStyle,
  }) : type = DialogType.editor;

  const Dialogs.loading({
    super.key,
    this.title,
    this.titleStyle,
    this.message,
    this.messageStyle,
  }) : type = DialogType.loading;

  const Dialogs.message({
    super.key,
    this.title,
    this.titleStyle,
    this.message,
    this.messageStyle,
  }) : type = DialogType.message;

  static Future<bool> showAlert(
    BuildContext context, {
    String? title,
    String? message,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Key? key,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (_) => Dialogs.alert(
        key: key,
        title: title,
        titleStyle: titleStyle,
        message: message,
        messageStyle: messageStyle,
      ),
    ).onError((_, __) => null).then((_) => _ is bool ? _ : false);
  }

  static Future<String> showEditor(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    String? message,
    TextStyle? messageStyle,
    Key? key,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (_) => Dialogs.editor(
        key: key,
        title: title,
        titleStyle: titleStyle,
        message: message,
        messageStyle: messageStyle,
      ),
    ).onError((_, __) => null).then((_) => _ is String ? _ : "");
  }

  static Future<bool> showLoading(
    BuildContext context, {
    Key? key,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (_) => Dialogs.loading(key: key),
    ).onError((_, __) => null).then((_) => _ is bool ? _ : false);
  }

  static Future<bool> showMessage(
    BuildContext context,
    String? message, {
    String? title,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Key? key,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (_) => Dialogs.message(
        key: key,
        title: title,
        titleStyle: titleStyle,
        message: message,
        messageStyle: messageStyle,
      ),
    ).onError((_, __) => null).then((_) => _ is bool ? _ : false);
  }

  Future open(BuildContext context, {Key? key}) {
    if (type.isAlert) {
      return showAlert(
        context,
        title: title,
        titleStyle: titleStyle,
        message: message,
        messageStyle: messageStyle,
        key: key,
      );
    } else if (type.isEditor) {
      return showEditor(
        context,
        title: title,
        titleStyle: titleStyle,
        message: message,
        messageStyle: messageStyle,
        key: key,
      );
    } else if (type.isLoading) {
      return showLoading(context, key: key);
    } else {
      return showMessage(
        context,
        message,
        title: title,
        titleStyle: titleStyle,
        messageStyle: messageStyle,
        key: key,
      );
    }
  }

  void close(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  State<Dialogs> createState() => _DialogsState();
}

class _DialogsState extends State<Dialogs> {
  late TextEditingController _editor;
  late DialogType type = widget.type;

  @override
  void initState() {
    if (type.isEditor) {
      _editor = TextEditingController();
    }
    super.initState();
  }

  @override
  void dispose() {
    if (type.isEditor) {
      _editor.dispose();
    }
    super.dispose();
  }

  Widget get _positiveButton {
    String label = "OK";
    if (type.isEditor) {
      label = "SUBMIT";
    }
    return ActionButton(
      text: label,
      onClick: (_) {
        if (type.isEditor) {
          Navigator.pop(_, _editor.text);
        } else {
          Navigator.pop(_, true);
        }
      },
    );
  }

  Widget get _negativeButton {
    return const ActionButton(
      text: "CANCEL",
      onClick: Navigator.pop,
    );
  }

  List<Widget> get _actions {
    if (widget.type.isAlert) {
      return [_negativeButton, _positiveButton];
    } else if (type.isLoading) {
      return [];
    } else {
      return [_positiveButton];
    }
  }

  Widget? _title(BuildContext context) {
    if (widget.type.isLoading) return null;
    final mTitle = widget.title ?? "";
    final isValidTitle = mTitle.isNotEmpty;
    if (!isValidTitle) return null;
    return Text(mTitle, style: widget.titleStyle);
  }

  Widget? _content(BuildContext context) {
    if (widget.type.isEditor) {
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
          ),
          child: TextField(
            controller: _editor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Type here...",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      );
    } else if (widget.type.isLoading) {
      return const Material(
        color: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 1,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeAlign: BorderSide.strokeAlignInside,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
        ),
      );
    } else {
      final msg = widget.message ?? "";
      final isValidMsg = msg.isNotEmpty;
      if (!isValidMsg) return null;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          msg,
          style: widget.messageStyle ?? Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = CupertinoAlertDialog(
      actions: _actions,
      title: _title(context),
      content: _content(context),
    );
    if (type.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: child,
      );
    } else {
      return child;
    }
  }
}

enum DialogType {
  alert,
  editor,
  loading,
  message;

  bool get isAlert => this == alert;

  bool get isEditor => this == editor;

  bool get isLoading => this == loading;

  bool get isMessage => this == message;
}

typedef OnActionButtonClick = void Function(BuildContext context);

class ActionButton extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Widget? child;
  final EdgeInsets padding;
  final OnActionButtonClick? onClick;

  const ActionButton({
    super.key,
    this.padding = const EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 24,
    ),
    this.text = "OK",
    this.style = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    this.child,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: GestureDetector(
        onTap: onClick != null ? () => onClick?.call(context) : null,
        child: Container(
          alignment: Alignment.center,
          padding: padding,
          color: Colors.transparent,
          child: child ?? Text(text, style: style),
        ),
      ),
    );
  }
}
