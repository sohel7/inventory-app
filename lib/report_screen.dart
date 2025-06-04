import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController nameController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> filteredItems = [];

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> searchItems() async {
    final data = await dbHelper.getFilteredItems(
      itemName: nameController.text, // ✅ fixed: changed from 'name:' to 'itemName:'
      startDate: startDate,
      endDate: endDate,
    );
    setState(() {
      filteredItems = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: Text("Report")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(hintText: "Item Name"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: pickDateRange,
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: searchItems,
                ),
              ],
            ),
          ),
          if (startDate != null && endDate != null)
            Text(
              "From ${dateFormat.format(startDate!)} to ${dateFormat.format(endDate!)}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (ctx, i) {
                final item = filteredItems[i];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text(
                      "Qty: ${item['quantity']} | Date: ${item['date']?.substring(0, 10)}"),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
