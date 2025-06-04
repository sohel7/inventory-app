import 'package:flutter/material.dart';
import 'package:inventory_app/report_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'db_helper.dart';

void main() {
  runApp(MaterialApp(
    home: InventoryScreen(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
  ));
}

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  bool _isEditing = false;
  int? _editingItemId;

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    loadItems();
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> loadItems() async {
    final data = await dbHelper.getItems();
    if (mounted) {
      setState(() {
        items = data;
      });
    }
  }

  Future<void> saveItem() async {
    final name = nameController.text.trim();
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;

    if (name.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid name and quantity")),
      );
      return;
    }

    if (_isEditing && _editingItemId != null) {
      await dbHelper.updateItem(_editingItemId!, name, quantity);
    } else {
      await dbHelper.insertItem(name, quantity);
    }

    nameController.clear();
    quantityController.clear();

    if (mounted) {
      setState(() {
        _isEditing = false;
        _editingItemId = null;
      });
    }

    loadItems();
  }

  void _listen() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("❌ Microphone permission denied.");
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('🔄 Speech status: $status'),
        onError: (error) => print('❌ Speech error: $error'),
      );

      print('🎤 Speech available: $available');

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: "bn_BD",
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          onResult: (val) {
            print("✅ Recognized Words: ${val.recognizedWords}");
            if (val.finalResult) {
              setState(() => _isListening = false);
              _parseVoiceInput(val.recognizedWords);
            }
          },
        );
      } else {
        print("❌ Speech recognition not available");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      print("🛑 Speech stopped.");
    }
  }

  void _parseVoiceInput(String input) {
    final parts = input.split(' ');
    if (parts.length >= 3) {
      final qty = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final name = parts.sublist(2).join(' ');
      if (qty > 0 && name.isNotEmpty) {
        nameController.text = name;
        quantityController.text = qty.toString();
        saveItem();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not recognize a valid item and quantity.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please speak in format: '3 pcs apple'")),
      );
    }
  }

  Future<void> reduceItemQuantity(int id, double currentQuantity) async {
    if (currentQuantity > 0) {
      await dbHelper.updateQuantity(id, currentQuantity - 1);
      loadItems();
    }
  }

  Future<void> deleteItem(int id) async {
    await dbHelper.deleteItem(id);
    loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory"),
        actions: [
          IconButton(
            icon: Icon(Icons.report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: "Item Name"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(hintText: "Quantity"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: saveItem,
                  icon: Icon(_isEditing ? Icons.check : Icons.add),
                  tooltip: _isEditing ? "Update Item" : "Add Item",
                ),
                IconButton(
                  icon: Icon(Icons.mic),
                  onPressed: _listen,
                  color: _isListening ? Colors.red : Colors.grey,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return ListTile(
                  title: Text("${item['name']}"),
                  subtitle: Text("Quantity: ${item['quantity']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                            _editingItemId = item['id'];
                            nameController.text = item['name'];
                            quantityController.text = item['quantity'].toString();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteItem(item['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
