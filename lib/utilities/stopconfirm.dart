import 'package:flutter/material.dart';

class StopConfirm extends StatelessWidget {
  StopConfirm({super.key});
  static bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stop route?'),
      content: const Text('Breadcrumbs will no longer be added. Your path is saved.'),
      actions: [
        TextButton(
          child: const Text("Stop route"),
          onPressed: () {
            confirmed = true;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            confirmed = false;
            Navigator.of(context).pop();
          })
      ],
    );
  }
}