library;

// Core exports
export 'src/core/callbacks.dart';
export 'src/core/media_config.dart';
export 'src/core/media_player_state.dart';
export 'src/core/subtitle_config.dart';

// Models exports
export 'src/models/media_event.dart';
export 'src/models/media_metadata.dart';
export 'src/models/media_progress.dart';
export 'src/models/media_source.dart';
export 'src/models/media_type.dart';
export 'src/models/subtitle_track.dart';

// Storage exports
export 'src/storage/media_storage_interface.dart';
export 'src/storage/media_storage_factory.dart';
export 'src/storage/sqflite_media_storage.dart';
export 'src/storage/in_memory_media_storage.dart';

// Video exports
export 'src/video/video_player_controller.dart';
export 'src/video/widgets/lms_video_player_widget.dart';
export 'src/video/widgets/minimal_video_player.dart';
export 'src/video/subtitle_controller.dart';
export 'src/video/subtitle_parser.dart';
export 'src/video/widgets/subtitle_display.dart';

// Audio exports
export 'src/audio/audio_player_controller.dart';
export 'src/audio/widgets/compact_audio_player.dart';
export 'src/audio/widgets/lms_audio_player_widget.dart';

// Document exports
export 'src/document/document_viewer_controller.dart';
export 'src/document/pdf_viewer_widget.dart';
export 'src/document/widgets/document_list_tile.dart';
export 'src/document/widgets/lms_document_viewer_page.dart';
export 'src/document/widgets/document_thumbnail.dart';

// Downloader exports
export 'src/downloader/download_aware_media_metadata.dart';
export 'src/downloader/download_manager_interface.dart';
export 'src/downloader/media_download_adapter.dart';
export 'src/downloader/widgets/download_button.dart';
export 'src/downloader/widgets/download_list_tile.dart';

// Main manager class
export 'src/lms_media_manager.dart';

// Re-export
export 'package:media_kit/media_kit.dart' hide SubtitleTrack;
export 'package:media_kit_video/media_kit_video.dart';
export 'package:file_picker/file_picker.dart';
