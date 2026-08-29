import 'dart:convert';
import 'dart:io';

/// Proxy configuration service.
/// Reads/writes proxy config to openbubbles_proxy.json next to the executable.
/// The Rust core reads this file at startup (before first HTTP request).
class ProxyConfigService {
  static final ProxyConfigService _instance = ProxyConfigService._internal();
  factory ProxyConfigService() => _instance;
  ProxyConfigService._internal();

  /// Get the path to the proxy config file (next to the executable).
  String get configPath {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir${Platform.pathSeparator}openbubbles_proxy.json';
  }

  /// Current proxy config (in-memory cache).
  ProxyConfig config = ProxyConfig.empty();

  /// Load proxy config from file.
  Future<ProxyConfig> load() async {
    try {
      final file = File(configPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        config = ProxyConfig.fromJson(json);
      }
    } catch (_) {
      // Ignore errors, use empty config
    }
    return config;
  }

  /// Save proxy config to file.
  Future<bool> save(ProxyConfig newConfig) async {
    try {
      config = newConfig;
      final file = File(configPath);
      final json = jsonEncode(newConfig.toJson());
      await file.writeAsString(json);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear proxy config.
  Future<bool> clear() async {
    try {
      config = ProxyConfig.empty();
      final file = File(configPath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether a proxy is currently configured.
  bool get hasProxy => config.url.isNotEmpty;
}

/// Proxy configuration data model.
class ProxyConfig {
  final String url;       // e.g. http://proxy.example.com:8080
  final String user;      // proxy username (optional)
  final String pass;      // proxy password (optional)
  final bool enabled;     // whether proxy is enabled

  const ProxyConfig({
    required this.url,
    this.user = '',
    this.pass = '',
    this.enabled = true,
  });

  factory ProxyConfig.empty() => const ProxyConfig(url: '', enabled: false);

  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      url: json['url'] as String? ?? '',
      user: json['user'] as String? ?? '',
      pass: json['pass'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'user': user,
      'pass': pass,
      'enabled': enabled,
    };
  }

  ProxyConfig copyWith({
    String? url,
    String? user,
    String? pass,
    bool? enabled,
  }) {
    return ProxyConfig(
      url: url ?? this.url,
      user: user ?? this.user,
      pass: pass ?? this.pass,
      enabled: enabled ?? this.enabled,
    );
  }
}
