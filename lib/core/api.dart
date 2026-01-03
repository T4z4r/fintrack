import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'database_helper.dart';

class Api {
  String? _token;
  final DatabaseHelper _db = DatabaseHelper();

  void setToken(String token) {
    _token = token;
  }

  Future<bool> _isOnline() async {
    // Assume connectivity check, for now return true
    return true; // Replace with actual check
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    return await http.get(url, headers: _headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    return await http.post(url, headers: _headers, body: json.encode(data));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    return await http.put(url, headers: _headers, body: json.encode(data));
  }

  Future<http.Response> patch(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    return await http.patch(url, headers: _headers, body: json.encode(data));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    return await http.delete(url, headers: _headers);
  }

  // Authentication
  Future<http.Response> register(Map<String, dynamic> data) async {
    return await post('/register', data);
  }

  Future<http.Response> login(Map<String, dynamic> data) async {
    return await post('/login', data);
  }

  Future<http.Response> getUser() async {
    return await get('/user');
  }

  Future<http.Response> logout() async {
    return await post('/logout', {});
  }

  // Dashboard
  Future<http.Response> getDashboard() async {
    return await get('/dashboard');
  }

  // Income
  Future<http.Response> getIncomeSources() async {
    return await get('/income-sources');
  }

  Future<http.Response> createIncomeSource(Map<String, dynamic> data) async {
    return await post('/income-sources', data);
  }

  Future<http.Response> getIncomeSource(int id) async {
    return await get('/income-sources/$id');
  }

  Future<http.Response> updateIncomeSource(
      int id, Map<String, dynamic> data) async {
    return await put('/income-sources/$id', data);
  }

  Future<http.Response> deleteIncomeSource(int id) async {
    return await delete('/income-sources/$id');
  }

  Future<http.Response> getIncomes() async {
    return await get('/incomes');
  }

  Future<http.Response> createIncome(Map<String, dynamic> data) async {
    return await post('/incomes', data);
  }

  Future<http.Response> getIncome(int id) async {
    return await get('/incomes/$id');
  }

  Future<http.Response> updateIncome(int id, Map<String, dynamic> data) async {
    return await put('/incomes/$id', data);
  }

  Future<http.Response> deleteIncome(int id) async {
    return await delete('/incomes/$id');
  }

  // Expenses
  Future<http.Response> getExpenses() async {
    return await get('/expenses');
  }

  Future<http.Response> createExpense(Map<String, dynamic> data) async {
    return await post('/expenses', data);
  }

  Future<http.Response> getExpense(int id) async {
    return await get('/expenses/$id');
  }

  Future<http.Response> updateExpense(int id, Map<String, dynamic> data) async {
    return await put('/expenses/$id', data);
  }

  Future<http.Response> deleteExpense(int id) async {
    return await delete('/expenses/$id');
  }

  // Assets
  Future<http.Response> getAssets() async {
    return await get('/assets');
  }

  Future<http.Response> createAsset(Map<String, dynamic> data) async {
    return await post('/assets', data);
  }

  Future<http.Response> getAsset(int id) async {
    return await get('/assets/$id');
  }

  Future<http.Response> updateAsset(int id, Map<String, dynamic> data) async {
    return await put('/assets/$id', data);
  }

  Future<http.Response> deleteAsset(int id) async {
    return await delete('/assets/$id');
  }

  // Debts
  Future<http.Response> getDebts() async {
    return await get('/debts');
  }

  Future<http.Response> createDebt(Map<String, dynamic> data) async {
    return await post('/debts', data);
  }

  Future<http.Response> getDebt(int id) async {
    return await get('/debts/$id');
  }

  Future<http.Response> updateDebt(int id, Map<String, dynamic> data) async {
    return await put('/debts/$id', data);
  }

  Future<http.Response> deleteDebt(int id) async {
    return await delete('/debts/$id');
  }

  Future<http.Response> getDebtPayments() async {
    return await get('/debt-payments');
  }

  Future<http.Response> getDebtPaymentsForDebt(int debtId) async {
    return await get('/debts/$debtId/payments');
  }

  Future<http.Response> createDebtPayment(Map<String, dynamic> data) async {
    return await post('/debt-payments', data);
  }

  Future<http.Response> getDebtPayment(int id) async {
    return await get('/debt-payments/$id');
  }

  Future<http.Response> updateDebtPayment(
      int id, Map<String, dynamic> data) async {
    return await put('/debt-payments/$id', data);
  }

  Future<http.Response> deleteDebtPayment(int id) async {
    return await delete('/debt-payments/$id');
  }

  Future<http.Response> getDebtPaymentsSummary() async {
    return await get('/debt-payments-summary');
  }

  // Budgets
  Future<http.Response> getBudgets() async {
    return await get('/budgets');
  }

  Future<http.Response> createBudget(Map<String, dynamic> data) async {
    return await post('/budgets', data);
  }

  Future<http.Response> getBudget(int id) async {
    return await get('/budgets/$id');
  }

  Future<http.Response> updateBudget(int id, Map<String, dynamic> data) async {
    return await put('/budgets/$id', data);
  }

  Future<http.Response> deleteBudget(int id) async {
    return await delete('/budgets/$id');
  }

  // Budget Items
  Future<http.Response> getBudgetItems() async {
    return await get('/budget-items');
  }

  Future<http.Response> getBudgetItemsForBudget(int budgetId) async {
    return await get('/budgets/$budgetId/items');
  }

  Future<http.Response> createBudgetItem(Map<String, dynamic> data) async {
    return await post('/budget-items', data);
  }

  Future<http.Response> getBudgetItem(int id) async {
    return await get('/budget-items/$id');
  }

  Future<http.Response> updateBudgetItem(int id, Map<String, dynamic> data) async {
    return await put('/budget-items/$id', data);
  }

  Future<http.Response> updateBudgetItemSpentAmount(int id, Map<String, dynamic> data) async {
    return await patch('/budget-items/$id/spent-amount', data);
  }

  Future<http.Response> deleteBudgetItem(int id) async {
    return await delete('/budget-items/$id');
  }

  Future<http.Response> getBudgetItemsSummary() async {
    return await get('/budget-items-summary');
  }

  // Investments
  Future<http.Response> getInvestments() async {
    return await get('/investments');
  }

  Future<http.Response> createInvestment(Map<String, dynamic> data) async {
    return await post('/investments', data);
  }

  Future<http.Response> getInvestment(int id) async {
    return await get('/investments/$id');
  }

  Future<http.Response> updateInvestment(int id, Map<String, dynamic> data) async {
    return await put('/investments/$id', data);
  }

  Future<http.Response> deleteInvestment(int id) async {
    return await delete('/investments/$id');
  }

  // Sync methods
  Future<void> syncIncomes() async {
    if (!await _isOnline()) return;
    final unsynced = await _db.getUnsyncedIncomes();
    for (var income in unsynced) {
      try {
        final response = await createIncome(income);
        if (response.statusCode == 201) {
          await _db.markIncomeSynced(income['id']);
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> syncExpenses() async {
    if (!await _isOnline()) return;
    final unsynced = await _db.getUnsyncedExpenses();
    for (var expense in unsynced) {
      try {
        final response = await createExpense(expense);
        if (response.statusCode == 201) {
          await _db.markExpenseSynced(expense['id']);
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> syncAssets() async {
    if (!await _isOnline()) return;
    final unsynced = await _db.getUnsyncedAssets();
    for (var asset in unsynced) {
      try {
        final response = await createAsset(asset);
        if (response.statusCode == 201) {
          await _db.markAssetSynced(asset['id']);
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> syncDebts() async {
    if (!await _isOnline()) return;
    final unsynced = await _db.getUnsyncedDebts();
    for (var debt in unsynced) {
      try {
        final response = await createDebt(debt);
        if (response.statusCode == 201) {
          await _db.markDebtSynced(debt['id']);
        }
      } catch (e) {
        // Handle error
      }
    }
  }
}
