import 'package:dio/dio.dart';

import '../../domain/entities/site.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

class SiteRemoteDataSource {
  Dio? _dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected error: $e',
        userMessage: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  Future<List<Site>> getSites({bool? isActive}) async {
    try {
      final dio = await _getDio();
      
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['is_active'] = isActive;

      print('🔍 Fetching sites with params: $queryParams');
      final response = await dio.get('/sites', queryParameters: queryParams);
      print('✅ Sites response status: ${response.statusCode}');
      print('📦 Sites response data type: ${response.data.runtimeType}');
      print('📄 Sites response data: ${response.data}');
      
      // Handle null or empty response
      if (response.data == null) {
        print('⚠️ Response data is null - returning empty list');
        return [];
      }
      
      // Extract data from response
      final List<dynamic> data = response.data is List 
          ? response.data as List<dynamic>
          : (response.data['data'] ?? response.data['sites'] ?? []) as List<dynamic>;
      
      print('📊 Extracted data list length: ${data.length}');
      
      // Empty list is valid - not an error!
      if (data.isEmpty) {
        print('✨ No sites found - returning empty list (NOT AN ERROR)');
        return <Site>[];
      }
      
      // Parse sites
      print('🔄 Parsing ${data.length} sites...');
      final sites = <Site>[];
      for (var i = 0; i < data.length; i++) {
        try {
          sites.add(Site.fromJson(data[i] as Map<String, dynamic>));
        } catch (e) {
          print('❌ Failed to parse site at index $i: $e');
        }
      }
      print('✅ Successfully parsed ${sites.length} sites');
      return sites;
      
    } on DioException catch (e) {
      print('🔴 Site API DioException: ${e.type}, ${e.message}, Status: ${e.response?.statusCode}');
      print('Response body: ${e.response?.data}');
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      if (e is ApiException) rethrow;
      print('💥 Site API Unexpected error: $e');
      print('Stack trace: $stackTrace');
      throw ApiException(
        message: 'Unexpected error: $e',
        userMessage: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  Future<Site> getSiteById(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.get('/sites/$id');
      return Site.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Site> createSite(Site site) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.post('/sites', data: site.toJson());
      return Site.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Site> updateSite(Site site) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.patch('/sites/${site.id}', data: site.toJson());
      return Site.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteSite(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      await dio.delete('/sites/$id');
    });
  }
}
