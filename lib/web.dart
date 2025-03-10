part of flutter_native_splash;

// Image template
class _WebLaunchImageTemplate {
  final String fileName;
  final double pixelDensity;
  _WebLaunchImageTemplate({required this.fileName, required this.pixelDensity});
}

/// Create Web splash screen
void _createWebSplash({
  required String? imagePath,
  required String? darkImagePath,
  required String? color,
  required String? darkColor,
  required String imageMode,
  required String? backgroundImage,
  required String? darkBackgroundImage,
}) {
  if (!File(_webIndex).existsSync()) {
    print('[Web] ' + _webIndex + ' not found.  Skipping Web.');
    return;
  }

  darkImagePath ??= imagePath;
  createWebImages(imagePath: imagePath, webSplashImages: [
    _WebLaunchImageTemplate(fileName: 'light-1x.png', pixelDensity: 1),
    _WebLaunchImageTemplate(fileName: 'light-2x.png', pixelDensity: 2),
    _WebLaunchImageTemplate(fileName: 'light-3x.png', pixelDensity: 3),
    _WebLaunchImageTemplate(fileName: 'light-4x.png', pixelDensity: 4),
  ]);
  createWebImages(imagePath: darkImagePath, webSplashImages: [
    _WebLaunchImageTemplate(fileName: 'dark-1x.png', pixelDensity: 1),
    _WebLaunchImageTemplate(fileName: 'dark-2x.png', pixelDensity: 2),
    _WebLaunchImageTemplate(fileName: 'dark-3x.png', pixelDensity: 3),
    _WebLaunchImageTemplate(fileName: 'dark-4x.png', pixelDensity: 4),
  ]);
  createBackgroundImages(
      backgroundImage: backgroundImage,
      darkBackgroundImage: darkBackgroundImage);
  createSplashCss(
      color: color,
      darkColor: darkColor,
      darkBackgroundImage: darkBackgroundImage,
      backgroundImage: backgroundImage);
  updateIndex(imageMode: imageMode, imagePath: imagePath);
}

void createBackgroundImages({
  required String? backgroundImage,
  required String? darkBackgroundImage,
}) {
  final backgroundDestination = _webSplashImagesFolder + 'light-background.png';
  if (backgroundImage == null) {
    final file = File(backgroundDestination);
    if (file.existsSync()) file.deleteSync();
  } else {
    // Copy will not work if the directory does not exist, so createSync
    // will ensure that the directory exists.
    File(backgroundDestination).createSync(recursive: true);
    File(backgroundImage).copySync(backgroundDestination);
  }

  final darkBackgroundDestination =
      _webSplashImagesFolder + 'dark-background.png';
  if (darkBackgroundImage == null) {
    final file = File(darkBackgroundDestination);
    if (file.existsSync()) file.deleteSync();
  } else {
    // Copy will not work if the directory does not exist, so createSync
    // will ensure that the directory exists.
    File(darkBackgroundDestination).createSync(recursive: true);
    File(darkBackgroundImage).copySync(darkBackgroundDestination);
  }
}

void createWebImages(
    {required String? imagePath,
    required List<_WebLaunchImageTemplate> webSplashImages}) {
  if (imagePath == null) {
    for (var template in webSplashImages) {
      final file = File(_webSplashImagesFolder + template.fileName);
      if (file.existsSync()) file.deleteSync();
    }
  } else {
    final image = decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) {
      print(imagePath + ' could not be read');
      exit(1);
    }
    print('[Web] Creating images');
    for (var template in webSplashImages) {
      _saveImageWeb(template: template, image: image);
    }
  }
}

void _saveImageWeb(
    {required _WebLaunchImageTemplate template, required Image image}) {
  var newFile = copyResize(
    image,
    width: image.width * template.pixelDensity ~/ 4,
    height: image.height * template.pixelDensity ~/ 4,
    interpolation: Interpolation.linear,
  );

  var file = File(_webSplashImagesFolder + template.fileName);
  file.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(newFile));
}

void createSplashCss(
    {required String? color,
    required String? darkColor,
    required String? backgroundImage,
    required String? darkBackgroundImage}) {
  print('[Web] Creating CSS');
  color ??= '000000';
  darkColor ??= color;
  var cssContent = _webCss
      .replaceFirst('[LIGHTBACKGROUNDCOLOR]', '#' + color)
      .replaceFirst('[DARKBACKGROUNDCOLOR]', '#' + darkColor);

  if (backgroundImage == null) {
    cssContent = cssContent.replaceFirst('[LIGHTBACKGROUNDIMAGE]', '');
  } else {
    cssContent = cssContent.replaceFirst('[LIGHTBACKGROUNDIMAGE]',
        'background-image: url("img/light-background.png");');
  }

  if (backgroundImage == null) {
    cssContent = cssContent.replaceFirst('[DARKBACKGROUNDIMAGE]', '');
  } else {
    cssContent = cssContent.replaceFirst('[DARKBACKGROUNDIMAGE]',
        'background-image: url("img/dark-background.png");');
  }

  var file = File(_webFolder + _webRelativeStyleFile);
  file.createSync(recursive: true);
  file.writeAsStringSync(cssContent);
}

void updateIndex({required String imageMode, required String? imagePath}) {
  print('[Web] Updating index.html');
  final webIndex = File(_webIndex);
  var lines = webIndex.readAsLinesSync();

  var foundExistingStyleSheet = false;
  var headCloseTagLine = 0;
  var bodyCloseTagLine = 0;
  var existingPictureLine = 0;
  var existingBodyLine = 0;

  final styleSheetLink =
      '<link rel="stylesheet" type="text/css" href="splash/style.css">';
  for (var x = 0; x < lines.length; x++) {
    var line = lines[x];

    if (line.contains(styleSheetLink)) {
      foundExistingStyleSheet = true;
    } else if (line.contains('</head>')) {
      headCloseTagLine = x;
    } else if (line.contains('</body>')) {
      bodyCloseTagLine = x;
    } else if (line.contains('<picture id="splash">')) {
      existingPictureLine = x;
    } else if (line.contains('<body>')) {
      existingBodyLine = x;
    }
  }

  if (!foundExistingStyleSheet) {
    lines[headCloseTagLine] = '  ' + styleSheetLink + '\n</head>';
  }

  if (existingPictureLine == 0) {
    if (imagePath != null) {
      for (var x = _indexHtmlPicture.length - 1; x >= 0; x--) {
        lines[bodyCloseTagLine] =
            _indexHtmlPicture[x].replaceFirst('[IMAGEMODE]', imageMode) +
                '\n' +
                lines[bodyCloseTagLine];
      }
    }
  } else {
    if (imagePath != null) {
      for (var x = 0; x < _indexHtmlPicture.length; x++) {
        lines[existingPictureLine + x] =
            _indexHtmlPicture[x].replaceFirst('[IMAGEMODE]', imageMode);
      }
    } else {
      lines.removeRange(
          existingPictureLine, existingPictureLine + _indexHtmlPicture.length);
    }
  }
  if (existingBodyLine != 0) {
    lines[existingBodyLine] =
        '<body style="position: fixed; inset: 0px; overflow: hidden; padding: 0px; margin: 0px; user-select: none; touch-action: none; font: 14px sans-serif; color: red;">';
  }
  webIndex.writeAsStringSync(lines.join('\n'));
}
