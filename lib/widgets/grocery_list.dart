import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var isLoading = true;
  String? errorString;

  // It pushes and wait the future of the router
  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItem()));
    // final url = Uri.https(
    //     'flutter-prep-e190f-default-rtdb.asia-southeast1.firebasedatabase.app',
    //     'shopping-list.json');
    // final response = await http.get(url);
    // _loadData();
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final url = Uri.https(
        'flutter-prep-e190f-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          errorString = 'Failed to fetch data. Please try again later.';
        });
      }

      print(response.body);
      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      // if (response.statusCode >= 400) {
      //   setState(() {
      //     errorString = "Api failed, please try again or check the server";
      //   });
      // }

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere((categoryItem) =>
                categoryItem.value.title == item.value['category'])
            .value;

        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      setState(() {
        _groceryItems = loadedItems;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorString = 'Something went wrong! Please try again later.';
      });
    }
  }

  void onRemoveGrocery(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    final url = Uri.https(
        'flutter-prep-e190f-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    setState(() {
      _groceryItems.remove(item);
    });
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Text('There is no item in the list');
    if (errorString != null) {
      content = Center(
        child: Text(errorString!),
      );
    } else if (isLoading) {
      content = Center(child: CircularProgressIndicator());
    } else if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
                key: ValueKey(_groceryItems[index].id),
                background: Container(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.75),
                ),
                onDismissed: (direction) {
                  onRemoveGrocery(_groceryItems[index]);
                },
                child: ListTile(
                  title: Text(_groceryItems[index].name),
                  leading: Container(
                    height: 24,
                    width: 24,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(
                    _groceryItems[index].quantity.toString(),
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ));
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add)),
          ],
        ),
        body: content);
  }
}
