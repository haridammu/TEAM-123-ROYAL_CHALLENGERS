import 'package:flutter/material.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String? token;

  const AnalyticsDashboardScreen({super.key, this.token});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      // In a real implementation, you would fetch this data from the backend
      // For now, we'll use sample data

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAnalyticsData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAnalyticsData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Key metrics
                        const Text(
                          'Key Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _MetricCard(
                              title: 'Active Users',
                              value: '1,248',
                              change: '+12%',
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                            _MetricCard(
                              title: 'Course Completions',
                              value: '342',
                              change: '+8%',
                              icon: Icons.school,
                              color: Colors.green,
                            ),
                            _MetricCard(
                              title: 'Avg. Engagement',
                              value: '72%',
                              change: '+5%',
                              icon: Icons.bar_chart,
                              color: Colors.orange,
                            ),
                            _MetricCard(
                              title: 'Revenue',
                              value: '\$12,480',
                              change: '+15%',
                              icon: Icons.attach_money,
                              color: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Engagement chart placeholder
                        const Text(
                          'Weekly Engagement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('Engagement Chart Visualization'),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Revenue trend placeholder
                        const Text(
                          'Monthly Revenue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('Revenue Trend Visualization'),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Course performance placeholder
                        const Text(
                          'Course Performance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('Course Performance Visualization'),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Detailed reports
                        const Text(
                          'Detailed Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _ReportItem(
                                  title: 'User Engagement Report',
                                  description:
                                      'Detailed analysis of user activity and engagement patterns',
                                  onTap: () {
                                    // View report
                                  },
                                ),
                                const Divider(),
                                _ReportItem(
                                  title: 'Course Performance Report',
                                  description:
                                      'Comprehensive analysis of course completion rates and student performance',
                                  onTap: () {
                                    // View report
                                  },
                                ),
                                const Divider(),
                                _ReportItem(
                                  title: 'Financial Report',
                                  description:
                                      'Revenue breakdown by course, subscription, and payment method',
                                  onTap: () {
                                    // View report
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: change.startsWith('+') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ReportItem({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
