import '../entities/worker.dart';

abstract class WorkerRepository {
  Future<List<Worker>> getWorkers({int? siteId, int? workTypeId, String? status});
  Future<Worker> getWorkerById(int id);
  Future<Worker> createWorker(Worker worker);
  Future<Worker> updateWorker(Worker worker);
  Future<void> deleteWorker(int id);
  Future<String> generateWorkerQRCode(int workerId);
  Future<List<Worker>> searchWorkers(String query);
}
