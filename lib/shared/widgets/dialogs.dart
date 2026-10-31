import 'package:flutter/material.dart';

/// Megerősítő párbeszédablak két gombbal. Igazat ad vissza, ha a
/// felhasználó a megerősítő gombot választotta.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Mégse',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Rövid üzenet a képernyő alján.
void showAppMessage(BuildContext context, String text) {
  showMessageWith(ScaffoldMessenger.of(context), text);
}

/// Rövid üzenet egy előre elkért [ScaffoldMessengerState]-tel. Akkor
/// hasznos, ha az üzenet egy képernyő bezárása után jelenik meg.
void showMessageWith(ScaffoldMessengerState messenger, String text) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
