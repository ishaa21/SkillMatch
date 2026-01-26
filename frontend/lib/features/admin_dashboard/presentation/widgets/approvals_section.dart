import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_stats_model.dart';

class ApprovalsSection extends StatefulWidget {
  final List<CompanyUser> companies;
  final Function(String) onApprove;
  final Function(String) onReject;
  final Function(String, String) onVerify;
  final VoidCallback onRefresh;

  const ApprovalsSection({
    super.key,
    required this.companies,
    required this.onApprove,
    required this.onReject,
    required this.onVerify,
    required this.onRefresh,
  });

  @override
  State<ApprovalsSection> createState() => _ApprovalsSectionState();
}

class _ApprovalsSectionState extends State<ApprovalsSection> {
  final Set<String> _processingIds = {};
  String _searchQuery = '';

  List<CompanyUser> get _filteredCompanies {
    if (_searchQuery.isEmpty) return widget.companies;
    final q = _searchQuery.toLowerCase();
    return widget.companies.where((c) {
      return c.companyName.toLowerCase().contains(q) ||
          c.industry.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _handleAction(String id, String action, {String? cin}) async {
    if (_processingIds.contains(id)) return;
    setState(() => _processingIds.add(id));
    try {
      if (action == 'approve') {
        await widget.onApprove(id);
      } else if (action == 'reject') {
        await widget.onReject(id);
      } else if (action == 'verify' && cin != null) {
        await widget.onVerify(id, cin);
      }
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
    if (widget.companies.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: Column(
        children: [
          // ---------- SEARCH + COUNT (WRAP SAFE) ----------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search companies',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('${widget.companies.length} Pending'),
                    backgroundColor: Colors.orange.shade50,
                    labelStyle: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- LIST ----------
          Expanded(
            child: _filteredCompanies.isEmpty
                ? const Center(child: Text('No companies found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCompanies.length,
                    itemBuilder: (context, index) {
                      final company = _filteredCompanies[index];
                      final isProcessing =
                          _processingIds.contains(company.id);
                      return _buildCompanyCard(company, isProcessing);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================= COMPANY CARD =================

  Widget _buildCompanyCard(CompanyUser company, bool isProcessing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10,
            offset: const Offset(0, 4)
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // ---------- HEADER ----------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _companyAvatar(company.companyName),
                const SizedBox(width: 16),
                Expanded(child: _companyInfo(company)),
              ],
            ),
          ),

          const Divider(height: 1),

          // ---------- CONTACT ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _contactRow(company.email),
          ),

          // ---------- ACTIONS ----------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Verify MCA',
                    icon: Icons.verified_user_outlined,
                    color: Colors.blue.shade700,
                    isOutlined: true,
                    onTap: isProcessing
                        ? null
                        : () => _showVerifyDialog(company.id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'Reject',
                    icon: Icons.close,
                    color: Colors.red.shade600,
                    isOutlined: true,
                    onTap: isProcessing
                        ? null
                        : () => _showRejectDialog(
                            company.id, company.companyName),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'Approve',
                    icon: Icons.check,
                    color: AppColors.deepGreen,
                    isOutlined: false,
                    onTap: isProcessing
                        ? null
                        : () => _showApproveDialog(company.id, company.companyName),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isOutlined,
    VoidCallback? onTap,
  }) {
    final style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          );

    return isOutlined 
      ? OutlinedButton(
          onPressed: onTap,
          style: style,
          child: Icon(icon, size: 20),
        )
      : ElevatedButton(
          onPressed: onTap,
          style: style,
          child: Icon(icon, size: 20),
        );
  }

  void _showApproveDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Company?'),
        content: Text('Are you sure you want to approve "$name"?\nThis will allow them to post internships.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAction(id, 'approve');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

  // ================= SUB WIDGETS =================

  Widget _companyInfo(CompanyUser c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.companyName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _infoChip(Icons.category_outlined, c.industry),
            _infoChip(Icons.location_on_outlined, _formatLocation(c.location)),
            _infoChip(Icons.schedule, 'Pending'),
          ],
        ),
      ],
    );
  }

  Widget _companyAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.softMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _contactRow(String email) {
    return Row(
      children: [
        const Icon(Icons.email_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _fullWidthButton({
    required String label,
    required IconData icon,
    required Color color,
    bool filled = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No pending approvals'));
  }

  // ================= DIALOGS =================

  void _showVerifyDialog(String companyId) {
    final cinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MCA Verification'),
        content: TextField(
          controller: cinController,
          decoration: const InputDecoration(labelText: 'CIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (cinController.text.isNotEmpty) {
                _handleAction(companyId, 'verify',
                    cin: cinController.text.trim());
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Company'),
        content: Text(name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAction(id, 'reject');
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
