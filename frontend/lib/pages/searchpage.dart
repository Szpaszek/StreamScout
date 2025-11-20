import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget{
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

// state class for SearchPage
class _SearchPageState extends State<SearchPage> {

  // function to performe a multi search

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: 
        Text('Search Page')
      )
    );
  }
}