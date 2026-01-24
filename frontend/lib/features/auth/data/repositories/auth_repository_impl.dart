import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/login_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<bool> login(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await remoteDataSource.login(request);
      
      await localDataSource.saveToken(response.accessToken);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }
}
