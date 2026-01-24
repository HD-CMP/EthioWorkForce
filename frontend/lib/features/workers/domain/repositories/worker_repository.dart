import '../entities/worker.dart';

abstract class WorkerRepository {
  Future<List<Worker>> getWorkers({String? siteId, String? workType, bool? isActive});
  Future<Worker> getWorkerById(int id);
  Future<Worker> createWorker(Worker worker);
  Future<Worker> updateWorker(Worker worker);
  Future<void> deleteWorker(int id);
  Future<String> generateWorkerQRCode(int workerId);
  Future<List<Worker>> searchWorkers(String query);
}
