/// 경로 유틸리티
bool isNetworkUrl(String path) {
  return path.startsWith('http://') ||
         path.startsWith('https://') ||
         path.startsWith('/api/');
}

bool isAssetPath(String path) {
  return path.startsWith('assets://') || path.startsWith('asset:');
}

String assetPathToAssetFile(String assetPath) {
  if (assetPath.startsWith('assets://')) {
    return assetPath.replaceFirst('assets://', 'assets/');
  }
  return assetPath;
}
