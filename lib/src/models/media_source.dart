import 'package:equatable/equatable.dart';

/// Abstract base class for all media sources
abstract class MediaSource extends Equatable {
  const MediaSource();

  String get uri;
  bool get isLocal;
  Map<String, String>? get headers;

  @override
  List<Object?> get props => [uri, isLocal, headers];
}

/// Network-based media source (streaming)
class NetworkMediaSource extends MediaSource {
  final String url;
  final Map<String, String>? authHeaders;

  const NetworkMediaSource({required this.url, this.authHeaders});

  @override
  String get uri => url;

  @override
  bool get isLocal => false;

  @override
  Map<String, String>? get headers => authHeaders;

  @override
  List<Object?> get props => [url, authHeaders];
}

/// Local file-based media source (offline)
class LocalMediaSource extends MediaSource {
  final String filePath;

  const LocalMediaSource({required this.filePath});

  @override
  String get uri => filePath;

  @override
  bool get isLocal => true;

  @override
  Map<String, String>? get headers => null;

  @override
  List<Object?> get props => [filePath];
}
