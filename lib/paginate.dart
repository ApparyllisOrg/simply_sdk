import 'package:flutter/cupertino.dart';
import 'package:simply_sdk/collection.dart';

import 'document.dart';

class Paginate extends StatefulWidget {
  final Collection collection;
  final Function itemBuilder;
  final Function getLoader;
  final int stepSize;

  const Paginate(
      {Key key,
      this.collection,
      this.itemBuilder,
      this.stepSize = 10,
      this.getLoader})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => PaginateState();
}

class PaginateState extends State<Paginate> {
  int currentOffset = 0;
  bool isLoading = true;
  bool reachedEnd = false;
  Collection _localCollection;

  ScrollController _scrollController = ScrollController();

  List<Document> docs;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels != 0) {
          getNextBatch();
        }
      }
    });

    currentOffset = widget.collection.getStart();
    _localCollection = widget.collection;
    getNextBatch();
  }

  void getNextBatch() async {
    if (reachedEnd || isLoading) {
      return;
    }

    isLoading = true;
    setState(() {});

    _localCollection.start(currentOffset);
    List<Document> newDocs = await _localCollection.get();
    docs.addAll(newDocs);

    if (newDocs.length < widget.stepSize) {
      reachedEnd = true;
    }

    currentOffset += widget.stepSize;
    isLoading = false;
    setState(() {});
  }

  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (int i = 0; i < docs.length; ++i) {
      var doc = docs[i];
      children.add(widget.itemBuilder(context, i, doc));
      children.add(SizedBox(
        height: 10,
      ));
    }

    if (isLoading) {
      children.add(widget.getLoader());
    }

    return ListView(
      children: children,
      controller: _scrollController,
    );
  }
}
