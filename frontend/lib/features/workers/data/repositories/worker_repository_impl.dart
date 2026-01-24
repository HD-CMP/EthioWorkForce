import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';
import '../datasources/worker_remote_datasource.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  final WorkerRemoteDataSource remoteDataSource;

  WorkerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Worker>> getWorkers({String? siteId, String? workType, bool? isActive}) async {
    try {
      return await remoteDataSource.getWorkers(
        siteId: siteId,
        workType: workType,
        isActive: isActive,
      );
    } catch (e) {
      throw Exception('Failed to fetch workers: $e');
    }
  }

  @override
  Future<Worker> getWorkerById(int id) async {
    try {
      return await remoteDataSource.getWorkerById(id);
    } catch (e) {
      throw Exception('Failed to fetch worker: $e');
    }
  }

  @override
  Future<Worker> createWorker(Worker worker) async {
    try {
      return await remoteDataSource.createWorker(worker);
    } catch (e) {
      throw Exception('Failed to create worker: $e');
    }
  }

  @override
  Future<Worker> updateWorker(Worker worker) async {
    try {
      return await remoteDataSource.updateWorker(worker);
    } catch (e) {
      throw Exception('Failed to update worker: $e');
    }
  }

  @override
  Future<void> deleteWorker(int id) async {
    try {
      await remoteDataSource.deleteWorker(id);
    } catch (e) {
      throw Exception('Failed to delete worker: $e');
    }
  }

  @override
  Future<String> generateWorkerQRCode(int workerId) async {
    try {
      return await remoteDataSource.generateWorkerQRCode(workerId);
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  @override
  Future<List<Worker>> searchWorkers(String query) async {
    try {
      return await remoteDataSource.searchWorkers(query);
    } catch (e) {
      throw Exception('Failed to search workers: $e');
    }
  }
}
