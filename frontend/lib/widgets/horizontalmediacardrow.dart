import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/widgets/mediacard.dart';

class HorizontalMediaCardRow extends StatelessWidget {
  final List<Media> mediaList;

  const HorizontalMediaCardRow({super.key, required this.mediaList});

  @override
  Widget build(BuildContext context) {
    // horizontal list of cards
    return SizedBox(
      height: 300, // fixed height for the horizontal scrolling row
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              right: 12.0, // Padding for each media element
            ),
            child: SizedBox(
              width: 150, //fixed width for each card
              child: Mediacard(media: mediaList[index]),
            ),
          );
        },
      ),
    );
  }
}
