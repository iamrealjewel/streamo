import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import 'streamo_loading.dart';

class UrlInputSection extends StatefulWidget {
  const UrlInputSection({super.key});

  @override
  State<UrlInputSection> createState() => _UrlInputSectionState();
}

class _UrlInputSectionState extends State<UrlInputSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
      _submit();
    }
  }

  void _submit() {
    final url = _controller.text.trim();
    print('DEBUG: _submit called with URL: "$url"');
    if (url.isEmpty) {
      print('DEBUG: URL is empty, returning.');
      return;
    }
    context.read<DownloadProvider>().fetchVideoInfo(url);
    _focusNode.unfocus();
  }

  void _clear() {
    _controller.clear();
    context.read<DownloadProvider>().clearVideoInfo();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // URL input row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste YouTube URL here...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      'https://www.youtube.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.play_circle_filled,
                        color: Color(0xFFFF0050),
                        size: 20,
                      ),
                    ),
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: _clear,
                          color: isDark
                              ? const Color(0xFF6B6B8A)
                              : Colors.grey,
                        )
                      : null,
                ),
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
              ),
            ),
            const SizedBox(width: 10),
            // Paste button
            _ActionButton(
              icon: Icons.content_paste_rounded,
              tooltip: 'Paste',
              onTap: _pasteFromClipboard,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search button
        SizedBox(
          width: double.infinity,
          child: Consumer<DownloadProvider>(
            builder: (context, provider, _) {
              return ElevatedButton.icon(
                onPressed: provider.isFetchingInfo ? null : _submit,
                icon: provider.isFetchingInfo
                    ? const StreamoLoading(size: 16, color: Colors.white)
                    : const Icon(Icons.search_rounded, size: 20),
                label: Text(
                  provider.isFetchingInfo ? 'Fetching...' : 'Get Video Info',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0050),
                  disabledBackgroundColor:
                      const Color(0xFFFF0050).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Quick tips
        Wrap(
          spacing: 8,
          children: [
            _TagChip(label: 'youtube.com/watch?v=...', isDark: isDark),
            _TagChip(label: 'youtu.be/...', isDark: isDark),
            _TagChip(label: 'Shorts', isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A45)
                  : const Color(0xFFE0E0F0),
            ),
          ),
          child: Icon(icon,
              color: isDark ? const Color(0xFF8A8AAA) : Colors.grey[600],
              size: 20),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _TagChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF0F0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A45)
              : const Color(0xFFD0D0F0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? const Color(0xFF6B6B8A) : Colors.grey[600],
        ),
      ),
    );
  }
}
