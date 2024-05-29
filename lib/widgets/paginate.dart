import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:simply_sdk/api/main.dart';
import 'package:simply_sdk/modules/collection.dart';
import 'package:simply_sdk/modules/http.dart';
import 'package:simply_sdk/simply_sdk.dart';
import '../types/document.dart';

class Paginate<T extends DocumentData> extends StatefulWidget {
  const Paginate({Key? key, required this.itemBuilder, this.stepSize = 10, this.extraParams, this.onBatchReceived, required this.getLoader, required this.emptyView, required this.sortBy, required this.sortOrder, required this.url, required this.documentConstructor, required this.prefixWidgets, required this.loadMoreText, this.spacingHeight = 10}) : super(key: key);
  final Widget Function(BuildContext, int, Document<T>) itemBuilder;
  final Function getLoader;
  final Function emptyView;
  final int stepSize;
  final double spacingHeight;
  final String sortBy;
  final int sortOrder;
  // Ex: v1/fronters
  final String url;
  final String? extraParams;
  final List<Widget> prefixWidgets;
  final DocumentConstructor<T> documentConstructor;
  final String loadMoreText;
  final ValueChanged<List<Document<T>>>? onBatchReceived;

  @override
  State<StatefulWidget> createState() => PaginateState<T>();
}

class PaginateState<T extends DocumentData> extends State<Paginate<T>> {
  int currentOffset = 0;
  bool isLoading = false;
  bool reachedEnd = false;

  final ScrollController _scrollController = ScrollController();

  List<Document<T>> docs = [];

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
    if (!API().auth().canSendHttpRequests()) {
      await API().auth().waitForAbilityToSendRequests();
    }

    return SimplyHttpClient().get(Uri.parse(API().connection().getRequestUrl('$url', 'sortBy=$sortBy&sortOrder=$sortOrder&limit=$stepSize&start=$currentOffset&sortUp=true&${additionalQuery ?? ""}'))).catchError((e) => generateFailedResponse(e));
  }

  void clear() {
    docs.clear();
    reachedEnd = false;
    currentOffset = 0;
    setState(() {});
  }

  void insertDocument(Document<T> doc) {
    docs.insert(0, doc);
  }

  void updateDocument(Document<T> doc) {
    updateDocumentInList(docs, doc, EChangeType.Update);
  }

  void deleteDocument(Document<T> doc) {
    updateDocumentInList(docs, doc, EChangeType.Delete);
  }

  Future<void> getNextBatch() async {
    if (reachedEnd || isLoading) {
      return;
    }

    isLoading = true;
    if (mounted) {
      setState(() {});
    }

    final response = await getNextPage(widget.url, widget.sortBy, widget.sortOrder, widget.stepSize, currentOffset, additionalQuery: widget.extraParams ?? '');
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      List<Map<String, dynamic>> responseDocs = (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();

      List<Document<T>> newDocs = [];
      responseDocs.forEach((element) {
        newDocs.add(widget.documentConstructor(element['id'], element['content']));
      });

      docs.addAll(newDocs);

      if (widget.onBatchReceived != null) {
        widget.onBatchReceived!(newDocs);
      }

      if (newDocs.isEmpty) {
        reachedEnd = true;
      }

      currentOffset += newDocs.length;
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    if (!isLoading && docs.isEmpty) {
      return widget.emptyView();
    }

    if (reachedEnd && docs.isEmpty) {
      return widget.emptyView();
    }

    List<Widget> children = [];

    children.addAll(widget.prefixWidgets);

    for (int i = 0; i < docs.length; ++i) {
      final doc = docs[i];
      children.add(widget.itemBuilder(context, i, doc));
      children.add(SizedBox(
        height: widget.spacingHeight,
      ));
    }

    if (isLoading) {
      children.add(widget.getLoader());
      return ListView(
        children: children,
        controller: _scrollController,
      );
    }

    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent == 0.0 && !reachedEnd) {
      children.add(ElevatedButton.icon(onPressed: getNextBatch, icon: const Icon(Icons.arrow_downward), label: Text(widget.loadMoreText)));
    }

    return ListView(
      children: children,
      controller: _scrollController,
    );
  }
}
