import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyEntry {
  final String acronym;
  final String fullName;
  const _FacultyEntry(this.acronym, this.fullName);
}

class _FacultyScreenState extends State<FacultyScreen> {
  StatusKind _statusKind = StatusKind.loading;
  String _statusText = 'Loading faculty data...';

  final Map<String, String> _facultyMap = {}; // acronym -> full name
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _statusKind = StatusKind.loading;
      _statusText = 'Loading faculty data...';
    });
    try {
      final result = await ApiService.instance.fetchRoutine();
      if (result.data.isEmpty) {
        setState(() {
          _statusKind = StatusKind.error;
          _statusText = 'No routine data found';
        });
        return;
      }

      _facultyMap.clear();
      for (final item in result.data) {
        if (item.facultyAcronym.isNotEmpty && item.facultyFullName.isNotEmpty) {
          _facultyMap[item.facultyAcronym.trim()] = item.facultyFullName.trim();
        }
      }

      setState(() {
        _statusKind = StatusKind.live;
        final count = _facultyMap.length;
        _statusText = '$count faculty member${count != 1 ? 's' : ''} loaded';
      });
    } catch (e) {
      setState(() {
        _statusKind = StatusKind.error;
        _statusText = 'Connection error. Check your internet.';
      });
    }
  }

  List<_FacultyEntry> get _allSorted {
    final all = _facultyMap.entries
        .map((e) => _FacultyEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => a.acronym.compareTo(b.acronym));
    return all;
  }

  List<_FacultyEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allSorted;

    final matches = _facultyMap.entries
        .where((e) =>
            e.key.toLowerCase().contains(q) || e.value.toLowerCase().contains(q))
        .map((e) => _FacultyEntry(e.key, e.value))
        .toList();

    matches.sort((a, b) {
      final aAcr = a.acronym.toLowerCase().contains(q);
      final bAcr = b.acronym.toLowerCase().contains(q);
      if (aAcr && !bAcr) return -1;
      if (!aAcr && bAcr) return 1;
      return a.acronym.compareTo(b.acronym);
    });
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final q = _query.trim();
    final isSearching = q.isNotEmpty;

    return Stack(
      children: [
        const BackgroundMesh(),
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text('Faculty Search',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text(
                  'Type a short acronym or part of a faculty name to find the full name.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Center(child: StatusBadge(kind: _statusKind, text: _statusText)),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                enabled: _statusKind == StatusKind.live,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by acronym or name (e.g. MR, Rahman)...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Text('🤷', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 10),
                        Text('No faculty found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  isSearching
                      ? '${results.length} result${results.length != 1 ? 's' : ''} found'
                      : 'Showing all ${results.length} faculty members',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final f = results[i];
                    return _FacultyCard(
                        acronym: f.acronym, fullName: f.fullName, query: q);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FacultyCard extends StatelessWidget {
  final String acronym;
  final String fullName;
  final String query;

  const _FacultyCard(
      {required this.acronym, required this.fullName, required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(acronym,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
