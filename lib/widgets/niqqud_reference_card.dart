import 'package:flutter/material.dart';

/// Reference data for the Hebrew system-keyboard niqqud guide.
///
/// Each entry is one physical keyboard row, read right-to-left, where the
/// niqqud diacritic immediately following a letter is the one offered in
/// that key's system-keyboard long-press popup.
class NiqqudReferenceData {
  static const List<String> rows = <String>[
    'פַםןוּטארֿקָ',
    'ףךלחִֹיע֫כגדּשְ',
    'ץתצֵמנהבסֶז',
  ];
}

/// Non-interactive reference card that mirrors the Hebrew system keyboard.
///
/// Each keyboard key is rendered as a [Chip] containing the base letter and
/// the [niqqud] diacritics offered in its long-press popup, so users can
/// reference the correct diacritics while entering a native word.
///
/// The card is shown inline next to the native-word input field. It is
/// dismissed either automatically when that field's text changes (handled by
/// the parent via the controller listener) or manually through [onClose].
class NiqqudReferenceCard extends StatelessWidget {
  final VoidCallback onClose;

  const NiqqudReferenceCard({required this.onClose, super.key});

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Noto Sans Hebrew',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const EdgeInsets _chipPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hebrew Letters & Niqqud',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'Segeo UI',
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          tooltip: 'Close',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _buildRows() {
    final rows = NiqqudReferenceData.rows;
    final List<Widget> rowWidgets = [];
    var globalIndex = 0;
    for (int r = 0; r < rows.length; r++) {
      final clusters = _characterClusters(rows[r]);
      rowWidgets.add(_buildRow(clusters, globalIndex));
      globalIndex += clusters.length;
      if (r < rows.length - 1) rowWidgets.add(_rowSeparator());
    }
    return Column(children: rowWidgets);
  }

  /// A clear, subtle divider drawn between keyboard rows.
  Widget _rowSeparator() {
    return const Divider(height: 16, thickness: 0.5, indent: 12, endIndent: 12);
  }

  /// Builds a single keyboard row as a horizontally-scrollable RTL line of
  /// [Chip]s so longer rows never overflow the input width.
  Widget _buildRow(List<String> clusters, int startIndex) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (int i = 0; i < clusters.length; i++) ...[
            _buildChip(clusters[i], (startIndex + i).isEven),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  /// Alternating background chips: even-positioned keys get a lighter shade
  /// than odd-positioned ones, producing a subtle checkerboard per row.
  Widget _buildChip(String label, bool light) {
    return Chip(
      label: Text(label, style: _labelStyle),
      backgroundColor: light ? Colors.grey.shade200 : Colors.grey.shade300,
      padding: _chipPadding,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  /// Splits one keyboard row into letter clusters, attaching any niqqud
  /// combining marks that follow a base letter so they render visibly under
  /// that letter instead of as orphaned (invisible) standalone glyphs.
  static List<String> _characterClusters(String row) {
    final clusters = <String>[];
    for (final rune in row.runes) {
      if (_isBaseLetter(rune)) {
        clusters.add(String.fromCharCode(rune));
      } else if (clusters.isNotEmpty) {
        clusters[clusters.length - 1] += String.fromCharCode(rune);
      } else {
        clusters.add(String.fromCharCode(rune));
      }
    }
    return clusters;
  }

  /// Whether [rune] is a Hebrew base letter (rather than a niqqud mark).
  static bool _isBaseLetter(int rune) =>
      (rune >= 0x05D0 && rune <= 0x05EA) || (rune >= 0x05F0 && rune <= 0x05F4);
}
