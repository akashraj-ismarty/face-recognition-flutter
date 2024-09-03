import 'package:flutter/material.dart';

class LoadingDialog extends StatefulWidget {
  @override
  _LoadingDialogState createState() => _LoadingDialogState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (bool shouldPop) {
            // Ensure the dialog cannot be dismissed by returning early from the closure.
            return;  // Returning void to satisfy the closure signature.
          },
          child: _LoadingDialogWidget(),
        );
      },
    );
  }

  static void updateProgress(BuildContext context, int current, int total) {
    final _LoadingDialogWidgetState? state =
    context.findAncestorStateOfType<_LoadingDialogWidgetState>();
    if (state != null) {
      state.updateProgress(current, total);
    } else {
      print("Warning: Unable to find _LoadingDialogWidgetState.");
    }
  }


  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

// Define the state class for LoadingDialog
class _LoadingDialogState extends State<LoadingDialog> {
  @override
  Widget build(BuildContext context) {
    // This widget does not actually build anything directly,
    // it provides static methods to show and hide a dialog.
    return Container(); // A placeholder widget, as this StatefulWidget does not directly display anything.
  }
}

class _LoadingDialogWidget extends StatefulWidget {
  @override
  _LoadingDialogWidgetState createState() => _LoadingDialogWidgetState();
}

class _LoadingDialogWidgetState extends State<_LoadingDialogWidget> {
  int _currentProgress = 0;
  int _totalProgress = 0;

  void updateProgress(int current, int total) {
    setState(() {
      _currentProgress = current;
      _totalProgress = total;
      print("Processing $current out of $total images...");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Processing $_currentProgress out of $_totalProgress..."),
        ],
      ),
    );
  }
}
