// lib/screens/provider_dashboard.dart
import 'package:flutter/material.dart';
import 'package:auto_care_provider/services/assignment_service.dart';
import 'package:auto_care_provider/models/assignment_model.dart';
import 'package:auto_care_provider/screens/jobs/available_jobs_screen.dart';
import 'package:auto_care_provider/screens/jobs/job_detail_screen.dart';
import 'package:auto_care_provider/widgets/assignment_card.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({Key? key}) : super(key: key);

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AssignmentModel> _available = [];
  List<AssignmentModel> _ongoing = [];
  List<AssignmentModel> _history = [];

  bool _loadingAvailable = true;
  bool _loadingOngoing = true;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadAvailable(), _loadOngoing(), _loadHistory()]);
  }

  Future<void> _loadAvailable() async {
    setState(() => _loadingAvailable = true);
    try {
      final items = await AssignmentService().getPendingAssignments();
      setState(() => _available = items);
    } catch (e) {
      debugPrint('Error loading available: $e');
    } finally {
      setState(() => _loadingAvailable = false);
    }
  }

  Future<void> _loadOngoing() async {
    setState(() => _loadingOngoing = true);
    try {
      // backend path might be 'assignments/active/' that returns assigned/accepted/in_progress
      final items = await AssignmentService.fetchAssignmentsByEndpoint(
          'assignments/active/');
      setState(() => _ongoing = items);
    } catch (e) {
      debugPrint('Error loading ongoing: $e');
    } finally {
      setState(() => _loadingOngoing = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      // If no dedicated endpoint, you may filter '/assignments/pending/' or create '/assignments/history/'
      final items = await AssignmentService.fetchAssignmentsByEndpoint(
          'assignments/completed/'); // create on backend if needed
      setState(() => _history = items);
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _onAccept(AssignmentModel a) async {
    final ok = await AssignmentService.acceptAssignment(a.id);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job accepted')));
      await _refreshAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to accept job'), backgroundColor: Colors.red));
    }
  }

  Future<void> _onReject(AssignmentModel a) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Job'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
              child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await AssignmentService.rejectAssignment(a.id, reason);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job rejected')));
      await _refreshAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to reject'), backgroundColor: Colors.red));
    }
  }

  Widget _buildList(List<AssignmentModel> items, {required bool loading}) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const Center(child: Text('No items'));
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final a = items[index];
          return AssignmentCard(
            assignment: a,
            onAccept: () => _onAccept(a),
            onReject: () => _onReject(a),
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => JobDetailsScreen(assignment: a)));
              await _refreshAll();
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_available, loading: _loadingAvailable),
          _buildList(_ongoing, loading: _loadingOngoing),
          _buildList(_history, loading: _loadingHistory),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshAll,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
