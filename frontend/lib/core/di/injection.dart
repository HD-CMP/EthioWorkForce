import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import '../database/app_database.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/payroll/data/datasources/payroll_remote_datasource.dart';
import '../../features/payroll/data/repositories/payroll_repository_impl.dart';
import '../../features/payroll/domain/repositories/payroll_repository.dart';
import '../../features/payroll/presentation/bloc/payroll_bloc.dart';
import '../../features/reports/data/datasources/reports_remote_datasource.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  final dio = await DioClient.createDio();
  getIt.registerSingleton<Dio>(dio);
  
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);
  
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<SharedPreferences>()),
  );
  
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  
  getIt.registerFactory(() => AuthBloc(
    loginUseCase: getIt<LoginUseCase>(),
    logoutUseCase: getIt<LogoutUseCase>(),
  ));
  
  getIt.registerLazySingleton<PayrollRemoteDataSource>(
    () => PayrollRemoteDataSource(getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<PayrollRepository>(
    () => PayrollRepositoryImpl(
      remoteDataSource: getIt<PayrollRemoteDataSource>(),
    ),
  );
  
  getIt.registerFactory(() => PayrollBloc(repository: getIt<PayrollRepository>()));

  getIt.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSource(getIt<Dio>()),
  );
}
