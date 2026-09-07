import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';

final class WorkOrdersLocalDataSource {
  WorkOrdersLocalDataSource({required Box<String> box}) : _box = box;

  final Box<String> _box;

  bool get hasCachedWorkOrders => _box.isNotEmpty;

  Future<void> saveWorkOrders(List<WorkOrder> workOrders) async {
    await _box.clear();

    final entries = <String, String>{
      for (final workOrder in workOrders)
        workOrder.id: jsonEncode(workOrder.toJson()),
    };

    await _box.putAll(entries);
  }

  List<WorkOrder> getWorkOrders() {
    return _box.values.map((value) {
      final decoded = jsonDecode(value);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid cached work order data');
      }

      return WorkOrder.fromJson(decoded);
    }).toList();
  }

  Future<void> clearWorkOrders() async {
    await _box.clear();
  }
}
