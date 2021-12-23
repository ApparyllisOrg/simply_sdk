import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import '../types/document.dart';

class Paginate extends StatefulWidget {
  final Function itemBuilder;
  final Function getLoader;
  final Function emptyView;
  final int stepSize;
  final String sortBy;
  final int sortOrder;
  // Ex: v1/fronters
  final String url;
  final DocumentConstructor documentConstructor;

  const Paginate(
      {Key? key,
      required this.itemBuilder,
      this.stepSize = 10,
      required this.getLoader,
      required this.emptyView,
      required this.sortBy,
      required this.sortOrder,
      required this.url,
      required this.documentConstructor})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => PaginateState();
}

class PaginateState extends State<Paginate> {
  int currentOffset = 0;
  bool isLoading = false;
  bool reachedEnd = false;

  ScrollController _scrollController = ScrollController();

  List<Document> docs = [];

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

    currentOffset = 0;
    getNextBatch();
  }

  void getNextBatch() async {
    if (reachedEnd || isLoading) {
      return;
    }

    isLoading = true;
    if (mounted) {
      setState(() {});
    }

    var response = await SimplyHttpClient().get(Uri.parse(API()
        .connection()
        .getRequestUrl('${widget.url}',
            'sortBy=${widget.sortBy}&sortOrder=${widget.sortOrder}&limit=${widget.stepSize}&start=$currentOffset')));

    List<Map<String, dynamic>> responseDocs = jsonDecode(response.body);

    List<Document> newDocs = [];
    responseDocs.forEach((element) {
      newDocs.add(widget.documentConstructor(element["id"], element["content"]));
    });

    docs.addAll(newDocs);

    if (newDocs.length <= 0) {
      reachedEnd = true;
    }

    currentOffset += newDocs.length;
    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    if (!isLoading && docs.length == 0) {
      return widget.emptyView();
    }

    if (reachedEnd && docs.isEmpty) {
      return widget.emptyView();
    }

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
