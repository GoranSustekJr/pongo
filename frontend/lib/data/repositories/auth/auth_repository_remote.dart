import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../domain/models/auth/user_profile.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/response_body.dart';
import '../../services/api/track_socket_service.dart';
import '../../services/auth/identity_service.dart';
import '../../services/local/secure_storage_service.dart';
import 'auth_repository.dart';

/// An [AuthRepository] backed by the Pongo API.
class AuthRepositoryRemote extends AuthRepository {
  /// Creates a repository and connects it to the clients that need tokens.
  AuthRepositoryRemote({
    required this._config,
    required this._apiClient,
    required this._socketService,
    required this._identityService,
    required this._storage,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    _apiClient
      ..accessTokenProvider = _accessTokenOf
      ..refreshSession = refreshSession
      ..onAccountDisabled = (() => _accountDisabled.add(null));
    _socketService
      ..accessTokenProvider = _accessTokenOf
      ..refreshSession = refreshSession;
  }

  static const _signInPath =
      'bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d';

  final AppConfig _config;
  final ApiClient _apiClient;
  final TrackSocketService _socketService;
  final IdentityService _identityService;
  final SecureStorageService _storage;
  final http.Client _httpClient;
  final _accountDisabled = StreamController<void>.broadcast();

  bool _isSignedIn = false;
  String? _accessToken;
  String _streamToken = '';

  String? _accessTokenOf() => _accessToken;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  String get streamToken => _streamToken;

  @override
  Stream<void> get onAccountDisabled => _accountDisabled.stream;

  @override
  Future<void> load() async {
    _accessToken = await _storage.read(StorageKeys.accessToken);
    _streamToken = await _storage.read(StorageKeys.streamToken) ?? '';
    _isSignedIn = await _storage.readBool(
      StorageKeys.signedIn,
      fallback: false,
    );
    notifyListeners();
  }

  @override
  Future<Result<bool>> signIn(SignInProvider provider) async {
    final IdentityCredential? credential;
    try {
      credential = switch (provider) {
        SignInProvider.google => await _identityService.signInWithGoogle(),
        SignInProvider.apple => await _identityService.signInWithApple(),
        SignInProvider.googleDesktop =>
          await _identityService.signInWithGoogleOnDesktop(),
      };
    } on Exception catch (e) {
      return Result.error(e);
    }
    if (credential == null) return const Result.ok(false);

    final result = await _apiClient.postUnauthenticated(_signInPath, {
      'apple': credential.apple,
      'id_token': credential.idToken,
      'platform': credential.platform,
      'device_id': credential.deviceId,
    });
    switch (result) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        await _setStreamToken(value['st'] as String? ?? '');
        final accessToken = value['at+JWT'] as String?;
        final refreshToken = value['rt+JWT'] as String?;
        if (accessToken == null || refreshToken == null) {
          return const Result.ok(false);
        }
        await _setSession(
          signedIn: true,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return const Result.ok(true);
    }
  }

  @override
  Future<bool> refreshSession() async {
    final refreshToken = await _storage.read(StorageKeys.refreshToken);
    final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse('${_config.serverUrl}renew_at'),
        body: jsonEncode({'jwt': refreshToken}),
      );
    } on Exception {
      return false;
    }

    if (response.statusCode == 401) {
      await signOut();
      return false;
    }
    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.utf8Body) as Map<String, dynamic>;
    _accessToken = data['at'] as String?;
    await _storage.write(StorageKeys.accessToken, _accessToken);
    if (data['st'] != null) await _setStreamToken(data['st'] as String);
    return true;
  }

  @override
  Future<void> signOut() =>
      _setSession(signedIn: false, accessToken: null, refreshToken: null);

  @override
  Future<Result<void>> deleteAccount() async {
    final result = await _apiClient.postForResponse('delete_account', {});
    switch (result) {
      case Ok():
        await signOut();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<UserProfile>> fetchProfile() async {
    final result = await _apiClient.post('user_data', {});
    switch (result) {
      case Ok(:final value):
        return Result.ok(UserProfile.fromMap(value));
      case Error(:final error):
        // Network failures keep the session; rejections end it.
        if (error is ApiException || error is AccountDisabledException) {
          await signOut();
        }
        return Result.error(error);
    }
  }

  Future<void> _setSession({
    required bool signedIn,
    required String? accessToken,
    required String? refreshToken,
  }) async {
    _isSignedIn = signedIn;
    _accessToken = accessToken;
    notifyListeners();
    await _storage.writeBool(StorageKeys.signedIn, value: signedIn);
    await _storage.write(StorageKeys.accessToken, accessToken);
    await _storage.write(StorageKeys.refreshToken, refreshToken);
  }

  Future<void> _setStreamToken(String token) async {
    _streamToken = token;
    await _storage.write(StorageKeys.streamToken, token);
  }
}
