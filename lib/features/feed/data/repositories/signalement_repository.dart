import 'dart:io';

import 'package:dio/dio.dart';
import '../../domain/models/signalement.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';

class SignalementResult {
  final List<Signalement> items;
  final int totalPages;
  final int page;

  SignalementResult({
    required this.items,
    this.totalPages = 1,
    this.page = 1,
  });
}

abstract class ISignalementRepository {
  Future<SignalementResult> getSignalements({int page = 1, int limit = 20});
  Future<Signalement> createSignalement(CreateSignalementDto dto);
}

class SignalementRepository implements ISignalementRepository {
  final Dio _dio;

  SignalementRepository({required Dio dio}) : _dio = dio;

  @override
  Future<SignalementResult> getSignalements({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.signalementCitoyen,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      final items = data is Map<String, dynamic> ? data['data'] ?? [] : (data ?? []);
      final meta = data is Map<String, dynamic> ? data['meta'] as Map<String, dynamic>? ?? {} : {};

      final list = (items as List)
          .map((item) => Signalement.fromJson(item as Map<String, dynamic>))
          .toList();

      return SignalementResult(
        items: list,
        page: (meta['page'] as num?)?.toInt() ?? page,
        totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (error) {
      throw UnknownException(error.toString());
    }
  }

  @override
  Future<Signalement> createSignalement(CreateSignalementDto dto) async {
    try {
      final bool hasPhoto = dto.photo != null;
      final Response response;
      if (hasPhoto) {
        final formData = FormData.fromMap({
          'titre': dto.titre,
          'description': dto.description,
          'categorieId': dto.categorieId,
          'adresse': dto.adresse,
          'latitude': dto.latitude,
          'longitude': dto.longitude,
          'photo': await MultipartFile.fromFile(
            dto.photo!.path,
            filename: dto.photo!.path.split(Platform.pathSeparator).last,
          ),
        });

        response = await _dio.post(
          ApiEndpoints.signalementCitoyen,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
      } else {
        response = await _dio.post(
          ApiEndpoints.signalementCitoyen,
          data: {
            'titre': dto.titre,
            'description': dto.description,
            'categorieId': dto.categorieId,
            'adresse': dto.adresse,
            'latitude': dto.latitude,
            'longitude': dto.longitude,
          },
        );
      }

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        return Signalement.fromJson(responseData);
      }

      throw ServerException('Réponse inattendue du serveur.');
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (error) {
      throw UnknownException(error.toString());
    }
  }

  AppException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final message = _extractErrorMessage(responseData) ?? error.message;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    if (statusCode == 401) {
      return const UnauthorizedException();
    }
    if (statusCode == 403) {
      return const UnauthorizedException('Accès refusé.');
    }
    if (statusCode == 404) {
      return const NotFoundException();
    }
    if (statusCode == 422) {
      return ValidationException(message ?? 'Données invalides.');
    }
    if (statusCode != null && statusCode >= 500) {
      return const ServerException();
    }

    return UnknownException(message ?? 'Erreur inconnue.');
  }

  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is String) {
      return responseData;
    }
    if (responseData is Map<String, dynamic>) {
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
      if (responseData['error'] != null) {
        return responseData['error'].toString();
      }
      if (responseData['errors'] != null) {
        return responseData['errors'].toString();
      }
    }
    return null;
  }
}

class CreateSignalementDto {
  final String titre;
  final String description;
  final String categorieId;
  final String adresse;
  final double latitude;
  final double longitude;
  final File? photo;

  CreateSignalementDto({
    required this.titre,
    required this.description,
    required this.categorieId,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    this.photo,
  });
}
