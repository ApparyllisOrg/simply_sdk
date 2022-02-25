import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
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
  final List<Widget> prefixWidgets;
  final DocumentConstructor documentConstructor;

  const Paginate({Key? key, required this.itemBuilder, this.stepSize = 10, required this.getLoader, required this.emptyView, required this.sortBy, required this.sortOrder, required this.url, required this.documentConstructor, required this.prefixWidgets}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PaginateState();
}

class PaginateState extends State<Paginate> {
  int currentOffset = 0;
  bool isLoading = false;
  bool reachedEnd = false;

  ScrollController _scrollController = ScrollController();
  double cachedOffset = 0;

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

  static Future<Response> getNextPage(String url, String sortBy, int sortOrder, int stepSize, int currentOffset, {String? additionalQuery}) async {
    return SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl('$url', 'sortBy=$sortBy&sortOrder=$sortOrder&limit=$stepSize&start=$currentOffset&sortUp=true&${additionalQuery ?? ""}')));
  }

  void getNextBatch() async {
    if (reachedEnd || isLoading) {
      return;
    }

    isLoading = true;
    cachedOffset = _scrollController.position.pixels;
    if (mounted) {
      setState(() {});
    }

    var response = await getNextPage(widget.url, widget.sortBy, widget.sortOrder, widget.stepSize, currentOffset);

    List<Map<String, dynamic>> responseDocs = (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();

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
    _scrollController.position.setPixels(cachedOffset);
  }

  Widget build(BuildContext context) {
    if (!isLoading && docs.length == 0) {
      return widget.emptyView();
    }

    if (reachedEnd && docs.isEmpty) {
      return widget.emptyView();
    }

    List<Widget> children = [];

    if (isLoading) {
      children.add(widget.getLoader());
      return ListView(
        children: children,
        controller: _scrollController,
      );
    }

    children.addAll(widget.prefixWidgets);

    for (int i = 0; i < docs.length; ++i) {
      var doc = docs[i];
      children.add(widget.itemBuilder(context, i, doc));
      children.add(SizedBox(
        height: 10,
      ));
    }

    return ListView(
      children: children,
      controller: _scrollController,
    );
  }
}
