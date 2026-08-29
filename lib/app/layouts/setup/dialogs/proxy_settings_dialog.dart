import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/services/network/proxy_config.dart';

/// Proxy settings dialog.
/// Allows configuring HTTP/HTTPS proxy with optional authentication.
/// Config is saved to openbubbles_proxy.json next to the executable,
/// which the Rust core reads at startup.
class ProxySettingsDialog extends StatefulWidget {
  const ProxySettingsDialog({super.key});

  @override
  State<ProxySettingsDialog> createState() => _ProxySettingsDialogState();
}

class _ProxySettingsDialogState extends State<ProxySettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _userController;
  late TextEditingController _passController;
  bool _enabled = false;
  bool _obscurePass = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cfg = ProxyConfigService().config;
    _urlController = TextEditingController(text: cfg.url);
    _userController = TextEditingController(text: cfg.user);
    _passController = TextEditingController(text: cfg.pass);
    _enabled = cfg.enabled && cfg.url.isNotEmpty;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// Build full proxy URL from host and port.
  String _buildProxyUrl(String host, String port) {
    if (host.isEmpty) return '';
    final scheme = host.startsWith('http://') || host.startsWith('https://')
        ? ''
        : 'http://';
    if (port.isNotEmpty) {
      return '$scheme$host:$port';
    }
    return '$scheme$host';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final url = _urlController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    final config = ProxyConfig(
      url: _enabled ? url : '',
      user: user,
      pass: pass,
      enabled: _enabled,
    );

    final ok = await ProxyConfigService().save(config);

    setState(() => _saving = false);

    if (ok) {
      Get.back();
      Get.snackbar(
        '代理设置已保存',
        _enabled
            ? '代理已启用。由于网络连接在启动时初始化，请重启应用使代理生效。'
            : '代理已禁用。请重启应用使更改生效。',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    } else {
      Get.snackbar(
        '保存失败',
        '无法写入代理配置文件，请检查目录权限。',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.network_cell, size: 24),
          const SizedBox(width: 10),
          const Text('网络代理设置'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用代理'),
                subtitle: const Text('通过代理服务器连接 Apple 服务'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                enabled: _enabled,
                decoration: const InputDecoration(
                  labelText: '代理地址',
                  hintText: 'http://proxy.example.com:8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) {
                  if (!_enabled) return null;
                  if (v == null || v.trim().isEmpty) {
                    return '请输入代理地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userController,
                enabled: _enabled,
                decoration: const InputDecoration(
                  labelText: '用户名（可选）',
                  hintText: '代理认证用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                enabled: _enabled,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: '密码（可选）',
                  hintText: '代理认证密码',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '支持 HTTP / HTTPS / SOCKS5 代理。'
                        '配置保存在程序目录下的 openbubbles_proxy.json。'
                        '修改后需重启应用生效。',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Get.back(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
