import 'package:cyberframework/cyberframework.dart';

/// Model cho file cần upload
class CyberAPIFile {
  bool isView;
  String fileName;
  String subFolder;
  String typeName;
  String strBase64;

  CyberAPIFile({
    this.isView = false,
    this.fileName = '',
    this.subFolder = '',
    this.typeName = '',
    this.strBase64 = '',
  });

  Map<String, dynamic> toJson() => {
    'isView': isView,
    'FileName': fileName,
    'SubFolder': subFolder,
    'typeName': typeName,
    'strBase64': strBase64,
  };

  factory CyberAPIFile.fromJson(Map<String, dynamic> json) {
    return CyberAPIFile(
      isView: json['isView'] ?? false,
      fileName: json['FileName'] ?? '',
      subFolder: json['SubFolder'] ?? '',
      typeName: json['typeName'] ?? '',
      strBase64: json['strBase64'] ?? '',
    );
  }

  /// Factory constructor để tạo từ file path và base64
  ///
  /// Format file path: /SubFolder/FileName.FileType
  /// Nếu không có subfolder => tự động sinh theo GUID
  ///
  /// Ví dụ:
  /// - "/images/photo.jpg" => SubFolder: "images", FileName: "photo.jpg", typeName: "jpg"
  /// - "photo.jpg" => SubFolder: "guid-generated", FileName: "photo.jpg", typeName: "jpg"
  factory CyberAPIFile.fromPath({
    required String filePath,
    required String base64Data,
    bool isView = true,
  }) {
    final parsedFile = _parseFilePath(filePath);

    return CyberAPIFile(
      isView: isView,
      fileName: parsedFile.fileName,
      subFolder: parsedFile.subFolder,
      typeName: parsedFile.fileType,
      strBase64: base64Data,
    );
  }

  /// Parse file path thành SubFolder, FileName, FileType
  static _ParsedFilePath _parseFilePath(String filePath) {
    // Loại bỏ khoảng trắng đầu cuối
    filePath = filePath.trim();

    // Xử lý path separator (/, \)
    filePath = filePath.replaceAll('\\', '/');

    // Tách thành parts
    final parts = filePath.split('/').where((p) => p.isNotEmpty).toList();

    String fileName;
    String subFolder;
    String fileType = '';

    if (parts.isEmpty) {
      // Trường hợp path rỗng
      fileName = 'file_${NewId()}';
      subFolder = NewId();
    } else if (parts.length == 1) {
      // Chỉ có filename, không có subfolder => tự động sinh subfolder
      fileName = parts[0];
      subFolder = NewId();
    } else {
      // Có cả subfolder và filename
      fileName = parts.last;
      subFolder = parts.sublist(0, parts.length - 1).join('/');
    }

    // Tách extension từ fileName
    final fileNameParts = fileName.split('.');
    if (fileNameParts.length > 1) {
      fileType = fileNameParts.last.toLowerCase();
    }

    // Xác định isView dựa trên fileType
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    final videoTypes = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'];
    final isViewable =
        imageTypes.contains(fileType) || videoTypes.contains(fileType);

    return _ParsedFilePath(
      fileName: fileName,
      subFolder: subFolder,
      fileType: fileType,
      isView: isViewable,
    );
  }
}

/// Helper class để lưu kết quả parse file path
class _ParsedFilePath {
  final String fileName;
  final String subFolder;
  final String fileType;
  final bool isView;

  _ParsedFilePath({
    required this.fileName,
    required this.subFolder,
    required this.fileType,
    required this.isView,
  });
}

/// Model cho request upload file
class CyberApiFilePost {
  String? strCyberToken;
  List<CyberAPIFile>? cyberAPIFiles;

  CyberApiFilePost({this.strCyberToken, this.cyberAPIFiles});

  /// Factory constructor để tạo từ list base64 và list file paths
  ///
  /// Ví dụ:
  /// ```dart
  /// final filePost = CyberApiFilePost.fromLists(
  ///   base64List: [base64Image1, base64Image2],
  ///   filePathList: ['/images/photo1.jpg', 'document.pdf'],
  /// );
  /// ```
  factory CyberApiFilePost.fromLists({
    required List<String> base64List,
    required List<String> filePathList,
  }) {
    if (base64List.length != filePathList.length) {
      throw ArgumentError(
        'base64List and filePathList must have the same length. '
        'Got ${base64List.length} base64 items and ${filePathList.length} file paths.',
      );
    }

    final cyberFiles = <CyberAPIFile>[];

    for (int i = 0; i < base64List.length; i++) {
      cyberFiles.add(
        CyberAPIFile.fromPath(
          filePath: filePathList[i],
          base64Data: base64List[i],
        ),
      );
    }

    return CyberApiFilePost(cyberAPIFiles: cyberFiles);
  }

  Map<String, dynamic> toJson() => {
    'strCyberToken': strCyberToken,
    'CyberAPIFiles': cyberAPIFiles?.map((f) => f.toJson()).toList(),
  };

  factory CyberApiFilePost.fromJson(Map<String, dynamic> json) {
    return CyberApiFilePost(
      strCyberToken: json['strCyberToken'],
      cyberAPIFiles: (json['CyberAPIFiles'] as List?)
          ?.map((item) => CyberAPIFile.fromJson(item))
          .toList(),
    );
  }

  /// Convert to request string với encryption
  /// strCyberToken được lấy từ UserInfo.strTokenId
  Future<String> convertToRequestString() async {
    final tokenData = {
      'Cyber-Date': DateTime.now().toIso8601String(),
      'Cyber-Token': await UserInfo.strTokenId,
    };

    final jsonStr = jsonEncode(tokenData);
    strCyberToken = V_MaHoa(jsonStr);

    return jsonEncode(toJson());
  }
}

/// Model cho response từ server sau khi upload
class CyberAPIFileReturn {
  bool status;
  String id;
  String name;
  String fileType;
  String url;

  CyberAPIFileReturn({
    this.status = false,
    this.id = '',
    this.name = '',
    this.fileType = '',
    this.url = '',
  });

  factory CyberAPIFileReturn.fromJson(Map<String, dynamic> json) {
    return CyberAPIFileReturn(
      status: json['status'] ?? false,
      id: json['id'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      fileType: json['FileType'] ?? json['fileType'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'id': id,
    'Name': name,
    'FileType': fileType,
    'url': url,
  };
}
