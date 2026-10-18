import 'package:dio/dio.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/registration_request.dart';

class AdminRemoteDatasource {
  final Dio dio;

  AdminRemoteDatasource(this.dio);

  Future<RegistrationRequestResponse> submitRegistrationRequest(
    RegistrationRequest request,
  ) async {
    try {
      final jsonData = request.toJson();
      print('DEBUG: Sending registration request: $jsonData');
      
      final response = await dio.post(
        '/registration/request',
        data: jsonData,
      );

      return RegistrationRequestResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      print('DEBUG: Exception caught - Type: ${e.runtimeType}');
      if (e is DioException) {
        print('DEBUG: DioException - Status: ${e.response?.statusCode}');
        print('DEBUG: Response data: ${e.response?.data}');
      }
      final apiError = ErrorHandler.extractError(e);
      throw apiError;
    }
  }

  Future<List<RegistrationRequestResponse>> getPendingRequests({int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (siteId != null) {
        queryParams['site_id'] = siteId;
      }
      
      final response = await dio.get(
        '/registration/requests/pending',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              RegistrationRequestResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final apiError = ErrorHandler.extractError(e);
      throw apiError;
    }
  }

  Future<List<RegistrationRequestResponse>> getMyRequests({
    String? status,
  }) async {
    try {
      final response = await dio.get(
        '/registration/requests',
        queryParameters: status != null ? {'status_filter': status} : null,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              RegistrationRequestResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final apiError = ErrorHandler.extractError(e);
      throw apiError;
    }
  }

  Future<Map<String, dynamic>> approveRequest(
    RegistrationApproval approval,
  ) async {
    try {
      final response = await dio.post(
        '/registration/approve',
        data: approval.toJson(),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      final apiError = ErrorHandler.extractError(e);
      throw apiError;
    }
  }

  Future<void> cancelRequest(int requestId) async {
    try {
      await dio.delete('/registration/requests/$requestId');
    } catch (e) {
      final apiError = ErrorHandler.extractError(e);
      throw apiError;
    }
  }
}
