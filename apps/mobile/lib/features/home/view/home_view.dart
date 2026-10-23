import 'package:carteira_core/carteira_core.dart';
import 'package:carteira_design_system/carteira_design_system.dart';
import 'package:flutter/material.dart' hide Page;

import '../../../l10n/strings.dart';

/// Home overview composed from the DesignSystem theme and spacing tokens.
class HomeView extends StatefulWidget {
  const HomeView({
    required this.users,
    required this.transactions,
    required this.onSignOut,
    super.key,
  });

  final UserRepository users;
  final TransactionRepository transactions;
  final Future<void> Function() onSignOut;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Future<void> _loadFuture;
  User? _user;
  Summary? _summary;
  List<Transaction> _recent = const [];
  AppError? _error;

  String get _month => DateTime.now().monthKey;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    _error = null;
    late Result<User> profileResult;
    late Result<Summary> summaryResult;
    late Result<Page<Transaction>> transactionsResult;
    await Future.wait<void>([
      widget.users.getProfile().then((result) => profileResult = result),
      widget.transactions
          .summary(_month)
          .then((result) => summaryResult = result),
      widget.transactions
          .list(TransactionFilter(month: _month, pageSize: 5))
          .then((result) => transactionsResult = result),
    ]);

    final failure =
        profileResult.errorOrNull ??
        summaryResult.errorOrNull ??
        transactionsResult.errorOrNull;
    if (failure != null) {
      _error = failure;
      if (failure is UnauthorizedError) {
        await widget.onSignOut();
      }
      return;
    }
    _user = profileResult.valueOrNull;
    _summary = summaryResult.valueOrNull;
    _recent = transactionsResult.valueOrNull?.items ?? const [];
  }

  void _retry() {
    setState(() => _loadFuture = _load());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loadFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (_error != null) return _errorView(context, _error!);
      return _home(context);
    },
  );

  Widget _home(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user;
    final summary = _summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.appName),
        actions: [
          IconButton(
            tooltip: Strings.signOut,
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _retry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              'Olá, ${user?.name.split(' ').first ?? ''}!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Strings.homeGreeting,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.semanticColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _summaryCard(context, summary),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Strings.recentTransactions,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Text(
                  formatMonthKey(_month),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.semanticColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_recent.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    Strings.noTransactions,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.semanticColors.muted,
                    ),
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var index = 0; index < _recent.length; index++) ...[
                      _transactionTile(context, _recent[index]),
                      if (index != _recent.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, Summary? summary) {
    final theme = Theme.of(context);
    final formatter = MoneyFormatter.forCurrency(Currency.brl);
    final colors = context.semanticColors;
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.monthBalance,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatter.format(summary?.balance ?? 0),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _summaryAmount(
                    context,
                    Strings.incomeLabel,
                    summary?.income ?? 0,
                    formatter,
                    colors.income,
                    Icons.south_west_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _summaryAmount(
                    context,
                    Strings.expenseLabel,
                    summary?.expense ?? 0,
                    formatter,
                    colors.expense,
                    Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryAmount(
    BuildContext context,
    String label,
    double amount,
    MoneyFormatter formatter,
    Color color,
    IconData icon,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary
                  .withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        formatter.format(amount),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _transactionTile(BuildContext context, Transaction transaction) {
    final colors = context.semanticColors;
    final color = switch (transaction.type) {
      TransactionType.income => colors.income,
      TransactionType.expense => colors.expense,
      TransactionType.transfer => colors.transfer,
    };
    final icon = switch (transaction.type) {
      TransactionType.income => Icons.south_west_rounded,
      TransactionType.expense => Icons.north_east_rounded,
      TransactionType.transfer => Icons.swap_horiz_rounded,
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${transaction.category ?? Strings.noCategory} · ${formatDate(transaction.date)}',
      ),
      trailing: Text(
        MoneyFormatter.forCurrency(Currency.brl)
            .formatSigned(transaction.signedAmount),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }

  Widget _errorView(BuildContext context, AppError error) => Scaffold(
    appBar: AppBar(title: const Text(Strings.appName)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: context.semanticColors.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _retry, child: const Text(Strings.retry)),
            TextButton(
              onPressed: widget.onSignOut,
              child: const Text(Strings.signOut),
            ),
          ],
        ),
      ),
    ),
  );
}
