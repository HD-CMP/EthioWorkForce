import '../../../workers/domain/entities/worker.dart';

class WorkerHierarchyNode {
  final Worker worker;
  final List<WorkerHierarchyNode> subordinates;
  bool isExpanded;
  final int level;

  WorkerHierarchyNode({
    required this.worker,
    this.subordinates = const [],
    this.isExpanded = false,
    this.level = 0,
  });

  bool get hasSubordinates => subordinates.isNotEmpty;

  WorkerHierarchyNode copyWith({
    Worker? worker,
    List<WorkerHierarchyNode>? subordinates,
    bool? isExpanded,
    int? level,
  }) {
    return WorkerHierarchyNode(
      worker: worker ?? this.worker,
      subordinates: subordinates ?? this.subordinates,
      isExpanded: isExpanded ?? this.isExpanded,
      level: level ?? this.level,
    );
  }
}

class WorkerHierarchyBuilder {
  static int _getRoleHierarchyLevel(String? workType) {
    if (workType == null) return 999;
    final role = workType.toLowerCase();
    
    if (role.contains('site manager') || role.contains('project manager')) return 1;
    if (role.contains('supervisor') || role.contains('foreman')) return 2;
    if (role.contains('engineer')) return 3;
    if (role.contains('technician') || role.contains('skilled')) return 4;
    if (role.contains('operator')) return 5;
    if (role.contains('worker') || role.contains('laborer') || role.contains('daily')) return 6;
    
    return 7;
  }

  static List<WorkerHierarchyNode> buildHierarchy(List<Worker> workers) {
    final Map<int, List<Worker>> supervisorMap = {};
    final List<Worker> topLevelWorkers = [];
    final Set<int> availableWorkerIds = workers.map((w) => w.id).whereType<int>().toSet();

    for (var worker in workers) {
      if (worker.supervisorId == null || !availableWorkerIds.contains(worker.supervisorId)) {
        topLevelWorkers.add(worker);
      } else {
        supervisorMap.putIfAbsent(worker.supervisorId!, () => []).add(worker);
      }
    }

    topLevelWorkers.sort((a, b) {
      if (a.workPlaceId != b.workPlaceId) {
        if (a.workPlaceId == null) return 1;
        if (b.workPlaceId == null) return -1;
        final workPlaceNameCompare = (a.workPlaceName ?? '').compareTo(b.workPlaceName ?? '');
        if (workPlaceNameCompare != 0) return workPlaceNameCompare;
      }
      
      final hierarchyCompare = _getRoleHierarchyLevel(a.workType)
          .compareTo(_getRoleHierarchyLevel(b.workType));
      if (hierarchyCompare != 0) return hierarchyCompare;
      
      final hasSubA = supervisorMap.containsKey(a.id) ? 0 : 1;
      final hasSubB = supervisorMap.containsKey(b.id) ? 0 : 1;
      if (hasSubA != hasSubB) return hasSubA.compareTo(hasSubB);
      
      return a.fullName.compareTo(b.fullName);
    });

    return topLevelWorkers.map((worker) {
      return _buildNode(worker, supervisorMap, 0);
    }).toList();
  }

  static WorkerHierarchyNode _buildNode(
    Worker worker,
    Map<int, List<Worker>> supervisorMap,
    int level,
  ) {
    final subordinates = supervisorMap[worker.id] ?? [];
    final subordinateNodes = subordinates.map((subordinate) {
      return _buildNode(subordinate, supervisorMap, level + 1);
    }).toList();

    subordinateNodes.sort((a, b) {
      final hierarchyCompare = _getRoleHierarchyLevel(a.worker.workType)
          .compareTo(_getRoleHierarchyLevel(b.worker.workType));
      if (hierarchyCompare != 0) return hierarchyCompare;
      
      final hasSubA = a.hasSubordinates ? 0 : 1;
      final hasSubB = b.hasSubordinates ? 0 : 1;
      if (hasSubA != hasSubB) return hasSubA.compareTo(hasSubB);
      
      return a.worker.fullName.compareTo(b.worker.fullName);
    });

    return WorkerHierarchyNode(
      worker: worker,
      subordinates: subordinateNodes,
      level: level,
    );
  }

  static List<WorkerHierarchyNode> flattenHierarchy(
    List<WorkerHierarchyNode> nodes,
  ) {
    final List<WorkerHierarchyNode> flattened = [];
    for (var node in nodes) {
      flattened.add(node);
      if (node.isExpanded && node.hasSubordinates) {
        flattened.addAll(flattenHierarchy(node.subordinates));
      }
    }
    return flattened;
  }

  static int getTotalWorkerCount(List<WorkerHierarchyNode> nodes) {
    int count = 0;
    for (var node in nodes) {
      count += 1;
      if (node.hasSubordinates) {
        count += getTotalWorkerCount(node.subordinates);
      }
    }
    return count;
  }

  static List<int> getAllWorkerIds(List<WorkerHierarchyNode> nodes) {
    final List<int> ids = [];
    for (var node in nodes) {
      if (node.worker.id != null) {
        ids.add(node.worker.id!);
      }
      if (node.hasSubordinates) {
        ids.addAll(getAllWorkerIds(node.subordinates));
      }
    }
    return ids;
  }
}
