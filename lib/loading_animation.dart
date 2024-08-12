import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // AbsorbPointer disables gestures on the background screen
        const AbsorbPointer(
          absorbing: true, // Set to true to disable gestures
          child: ModalBarrier(
            //color: Colors.black.withOpacity(0.5), // Adjust opacity as needed
            dismissible: false, // Prevents user from dismissing the barrier
          ),
        ),
        Center(
          child: Lottie.asset(
            'assets/loader.json',
            height: 120,
            width: 120,
          ),
        ),
      ],
    );
  }
}