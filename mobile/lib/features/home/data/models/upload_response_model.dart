class UploadResponseModel {
  final String url;
  final String publicId;
  final String type;

  UploadResponseModel({
    required this.url,
    required this.publicId,
    required this.type,
  });

  factory UploadResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadResponseModel(
      url: json['url'] as String,
      publicId: json['publicId'] as String,
      type: json['type'] as String,
    );
  }
}
