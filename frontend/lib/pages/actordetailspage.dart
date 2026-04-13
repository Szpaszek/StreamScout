import 'package:flutter/material.dart';
import 'package:frontend/models/actor.dart';
import 'package:frontend/widgets/horizontalmediacardrow.dart';

class ActorDetailsPage extends StatelessWidget {
  final Actor actor;
  final VoidCallback onBack;

  ActorDetailsPage({super.key, required this.actor, required this.onBack});

  // TODO: more details using api and movies played in
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

                // profile header (image left, info right)
                Padding(
                  padding: const EdgeInsetsGeometry.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // actor image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          actor.profilePath ?? '',
                          width: 140,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, s) => Container(
                            width: 140,
                            height: 200,
                            color: Colors.white10,
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // actor info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              actor.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // role tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                "Actor",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Featured in ${actor.knownFor.length} top titles",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // "Known For" section
                const Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 16.0),
                  child: Text(
                    "Known For",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                HorizontalMediaCardRow(mediaList: actor.knownFor),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
