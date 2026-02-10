enum StoryMediaType { photo, video, gallery }

class StoryDraft {
  final StoryMediaType type;
  final String filePath; // image/video file path
  const StoryDraft({required this.type, required this.filePath});
}
