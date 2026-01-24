import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_stats_model.dart';

class InternshipsSection extends StatefulWidget {
  final List<InternshipModel> internships;
  final Function(String) onToggleStatus;
  final VoidCallback onRefresh;

  const InternshipsSection({
    super.key,
    required this.internships,
    required this.onToggleStatus,
    required this.onRefresh,
  });

  @override
  State<InternshipsSection> createState() => _InternshipsSectionState();
}

class _InternshipsSectionState extends State<InternshipsSection> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _workModeFilter = 'all';
  final Set<String> _processingIds = {};

  List<InternshipModel> get _filteredInternships {
    return widget.internships.where((i) {
      if (_statusFilter == 'active' && i.isActive != true) return false;
      if (_statusFilter == 'inactive' && i.isActive != false) return false;
      if (_workModeFilter != 'all' && i.workMode != _workModeFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!i.title.toLowerCase().contains(q) &&
            !i.companyName.toLowerCase().contains(q) &&
            !i.location.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _handleToggle(String id) async {
    if (_processingIds.contains(id)) return;
    setState(() => _processingIds.add(id));
    try {
      await widget.onToggleStatus(id);
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  String _formatLocation(String location) {
    if (location.trim().startsWith('{') || location.contains('coordinates')) {
      return 'Location Set';
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.internships.where((i) => i.isActive).length;
    final inactiveCount = widget.internships.length - activeCount;

    return Column(
      children: [
        // ---------- STATS (VERTICAL ON MOBILE) ----------
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildQuickStat('Total Listings', '${widget.internships.length}', Icons.list_alt, Colors.blue),
              const SizedBox(height: 12),
              _buildQuickStat('Active', '$activeCount', Icons.check_circle, Colors.green),
              const SizedBox(height: 12),
              _buildQuickStat('Inactive', '$inactiveCount', Icons.pause_circle, Colors.grey),
            ],
          ),
        ),

        // ---------- FILTERS ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _searchField(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dropdown(_statusFilter, ['all', 'active', 'inactive'], (v) => setState(() => _statusFilter = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdown(_workModeFilter, ['all', 'Remote', 'On-site', 'Hybrid'], (v) => setState(() => _workModeFilter = v))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---------- LIST ----------
        Expanded(
          child: _filteredInternships.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredInternships.length,
                    itemBuilder: (context, index) {
                      final internship = _filteredInternships[index];
                      final isProcessing = _processingIds.contains(internship.id);
                      return _buildInternshipCard(internship, isProcessing);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ================= CARD =================

  Widget _buildInternshipCard(InternshipModel internship, bool isProcessing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _companyAvatar(internship),
                const SizedBox(width: 12),
                Expanded(child: _internshipInfo(internship)),
              ],
            ),
          ),

          // ---------- STATS (WRAP = NO OVERFLOW) ----------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _statChip(Icons.people_outline, '${internship.applicantCount} Applications'),
                      ...internship.statusBreakdown.take(3).map((s) {
                        return _statText('${s['_id']}: ${s['count']}');
                      }),
                    ],
                  ),
                ),
                Switch(
                  value: internship.isActive,
                  onChanged: isProcessing || internship.companySuspended ? null : (_) => _handleToggle(internship.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUB WIDGETS =================

  Widget _internshipInfo(InternshipModel i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(i.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        Row(
          children: [
            const Icon(Icons.business_outlined, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(i.companyName, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _infoTag(_getWorkModeIcon(i.workMode), i.workMode),
            _infoTag(Icons.location_on_outlined, _formatLocation(i.location)),
            if (i.stipend != null)
              _infoTag(Icons.payments_outlined, '${i.stipend!['currency'] ?? 'INR'} ${i.stipend!['amount']}'),
          ],
        ),

        if (i.skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: i.skills.map((s) => _skillChip(s)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _companyAvatar(InternshipModel i) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.softMint, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(i.companyName.isNotEmpty ? i.companyName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _statText(String text) => Text(text, style: const TextStyle(fontSize: 11));

  Widget _infoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _skillChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search internships'),
    );
  }

  Widget _dropdown(String value, List<String> items, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v!),
      decoration: const InputDecoration(isDense: true),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No internships found'));
  }

  IconData _getWorkModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'remote':
        return Icons.home_work_outlined;
      case 'on-site':
        return Icons.business_outlined;
      case 'hybrid':
        return Icons.compare_arrows;
      default:
        return Icons.work_outline;
    }
  }
}
