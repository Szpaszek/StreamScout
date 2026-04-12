import 'package:flutter/material.dart';
import 'package:frontend/models/actor.dart';

class ActorDetailsPage extends StatelessWidget {
  final Actor actor;
  final VoidCallback onBack;

  ActorDetailsPage({super.key, required this.actor, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept back button press to close the details view instead of navigating back
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // if the page already popped do nothing, otherwise call the onBack callback
        if (didPop) return;

        // trigger custom close logic
        onBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, //left aligned
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    label: Text(
                      "Back",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                // actor profile picture
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      actor.profilePath ?? '',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,

                      // fallback if image fails to load
                      errorBuilder: (context, error, s) => SizedBox(
                        height: 220,
                        child: Center(
                          child: const Icon(
                            Icons.movie,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
