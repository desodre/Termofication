class AppMetadata {
  static String _version = '0.0.0';
  static String _buildNumber = '';

  static void initialize({
    required String version,
    required String buildNumber,
  }) {
    _version = version;
    _buildNumber = buildNumber;
  }

  static String get appVersionLabel {
    if (_buildNumber.isEmpty) {
      return 'v$_version';
    }

    return 'v$_version+$_buildNumber';
  }
}
