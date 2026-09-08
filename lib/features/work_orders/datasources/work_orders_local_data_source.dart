import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';

abstract interface class WorkOrdersLocalDataSource {
  bool get hasCachedWorkOrders;

  Future<void> saveWorkOrders(List<WorkOrder> workOrders);

  List<WorkOrder> getWorkOrders();

  WorkOrder? getWorkOrderById(String id);

  Future<void> clearWorkOrders();
}

final class WorkOrdersLocalDataSourceImpl implements WorkOrdersLocalDataSource {
  WorkOrdersLocalDataSourceImpl({required Box<String> box}) : _box = box;

  final Box<String> _box;

  @override
  bool get hasCachedWorkOrders => _box.isNotEmpty;

  @override
  Future<void> saveWorkOrders(List<WorkOrder> workOrders) async {
    await _box.clear();

    final entries = <String, String>{
      for (final workOrder in workOrders)
        workOrder.id: jsonEncode(workOrder.toJson()),
    };

    await _box.putAll(entries);
  }

  @override
  List<WorkOrder> getWorkOrders() {
    return _box.values.map((value) {
      final decoded = jsonDecode(value);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid cached work order data');
      }

      return WorkOrder.fromJson(decoded);
    }).toList();
  }

  @override
  WorkOrder? getWorkOrderById(String id) {
    final value = _box.get(id);

    if (value == null) {
      return null;
    }

    return _decodeWorkOrder(value);
  }

  @override
  Future<void> clearWorkOrders() async {
    await _box.clear();
  }

  WorkOrder _decodeWorkOrder(String value) {
    final decoded = jsonDecode(value);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid cached work order data');
    }

    return WorkOrder.fromJson(decoded);
  }
}
