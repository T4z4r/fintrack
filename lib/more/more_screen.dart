import 'package:flutter/material.dart';
import '../investment/investment_screen.dart';
import '../debt/debt_screen.dart';
import '../asset/asset_screen.dart';

class MoreScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const MoreScreen({Key? key, required this.onNavigate}) : super(key: key);

  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _selectedFeature = 0; // 0 = overview, 1 = investments, 2 = debts, 3 = assets

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Feature navigation tabs
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(0, 'Overview', Icons.dashboard),
                ),
                Expanded(
                  child: _buildTabButton(1, 'Investment', Icons.show_chart),
                ),
                Expanded(
                  child: _buildTabButton(2, 'Debts', Icons.money_off),
                ),
                Expanded(
                  child: _buildTabButton(3, 'Assets', Icons.inventory),
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: _getFeatureContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final bool isSelected = _selectedFeature == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFeature = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF72140C) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFeatureContent() {
    switch (_selectedFeature) {
      case 0:
        return _buildOverview();
      case 1:
        return InvestmentScreen();
      case 2:
        return DebtScreen();
      case 3:
        return AssetScreen();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Features',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Color(0xFF72140C),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose a feature from the tabs above or browse the quick access cards below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          
          // Quick access cards
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          
          _buildQuickAccessCard(
            icon: Icons.show_chart,
            title: 'Investment Portfolio',
            subtitle: 'Track your investments and returns',
            color: Colors.green,
            onTap: () => setState(() => _selectedFeature = 1),
          ),
          SizedBox(height: 12),
          
          _buildQuickAccessCard(
            icon: Icons.money_off,
            title: 'Debt Management',
            subtitle: 'Manage debts and track payments',
            color: Colors.red,
            onTap: () => setState(() => _selectedFeature = 2),
          ),
          SizedBox(height: 12),
          
          _buildQuickAccessCard(
            icon: Icons.inventory,
            title: 'Asset Tracking',
            subtitle: 'Monitor your valuable assets',
            color: Colors.blue,
            onTap: () => setState(() => _selectedFeature = 3),
          ),
          SizedBox(height: 32),
          
          // Info card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF72140C),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Pro Tip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF72140C),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Use the tabs above to quickly switch between different features within the More section. Each tab maintains its own state and data.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
