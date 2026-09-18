import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/referral/presentation/providers/referral_providers.dart';
import 'package:zennyt/features/wallet/domain/entities/wallet.dart';
import 'package:zennyt/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Portefeuille (maquettes 114/118) : solde, carte, actions et écritures.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: CustomAppBar(title: 'Wallet', onBack: () => context.pop()),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refresh();
          await ref.read(walletTransactionsProvider.future);
        },
        child: walletAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            children: [
              const SizedBox(height: 120),
              const Center(child: Text('Could not load your wallet.', style: TextStyle(color: Color(0xFFE53935)))),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(walletProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (wallet) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _BalanceCard(wallet: wallet),
              const SizedBox(height: 16),
              _ActionsRow(
                wallet: wallet,
                onWithdraw: () => _withdraw(context, ref, wallet),
                onChangeCard: () => _editCard(context, ref, wallet),
                onShareLink: () => _shareLink(context, ref),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 12),
              transactionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('Could not load transactions.', style: TextStyle(color: Color(0xFFE53935))),
                ),
                data: (transactions) => transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text('No transactions yet.', style: TextStyle(color: Color(0xFF8A90A2))),
                        ),
                      )
                    : Column(
                        children: transactions.map((t) => _TransactionTile(transaction: t)).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareLink(BuildContext context, WidgetRef ref) async {
    try {
      final link = await ref.read(referralLinkProvider.future);
      await Clipboard.setData(ClipboardData(text: link.url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral link copied!'), backgroundColor: Color(0xFF2AC052)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your link.')),
        );
      }
    }
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref, Wallet wallet) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            helperText: 'Available: ${wallet.balanceDisplay}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0 || !context.mounted) return;
    try {
      await ref.read(walletProvider.notifier).withdraw(amount);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal recorded'), backgroundColor: Color(0xFF2AC052)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }

  Future<void> _editCard(BuildContext context, WidgetRef ref, Wallet wallet) {
    return WalletCardDialog.show(context, hasCard: wallet.card != null);
  }
}

class _BalanceCard extends StatelessWidget {
  final Wallet wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(HugeIcons.strokeRoundedWallet01, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Your balance',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              const Spacer(),
              if (wallet.card != null)
                Text(wallet.card!.brand,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            wallet.balanceDisplay,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            wallet.card == null ? 'No card on file' : wallet.card!.masked,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onWithdraw;
  final VoidCallback onChangeCard;
  final VoidCallback onShareLink;
  const _ActionsRow({
    required this.wallet,
    required this.onWithdraw,
    required this.onChangeCard,
    required this.onShareLink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Action(icon: HugeIcons.strokeRoundedArrowDownLeft01, label: 'Withdraw', onTap: onWithdraw),
        const SizedBox(width: 10),
        _Action(
          icon: HugeIcons.strokeRoundedCreditCard,
          label: wallet.card == null ? 'Add card' : 'Change card',
          onTap: onChangeCard,
        ),
        const SizedBox(width: 10),
        _Action(icon: HugeIcons.strokeRoundedLink01, label: 'Share link', onTap: onShareLink),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6ECF7)),
          ),
          child: Column(
            children: [
              AppIcon(icon, color: const Color(0xFF21438A), size: 20),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final positive = transaction.amountCents >= 0;
    final color = positive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: AppIcon(positive ? HugeIcons.strokeRoundedArrowDown02 : HugeIcons.strokeRoundedArrowUp02,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              transaction.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 13.5),
            ),
          ),
          Text(transaction.amountDisplay,
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

/// Add / change card dialog (maquettes 107/119). The full number and CVV are
/// sent to the server but never stored there.
class WalletCardDialog extends ConsumerStatefulWidget {
  final bool hasCard;
  const WalletCardDialog({super.key, required this.hasCard});

  static Future<void> show(BuildContext context, {required bool hasCard}) {
    return showDialog<void>(
      context: context,
      builder: (_) => WalletCardDialog(hasCard: hasCard),
    );
  }

  @override
  ConsumerState<WalletCardDialog> createState() => _WalletCardDialogState();
}

class _WalletCardDialogState extends ConsumerState<WalletCardDialog> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final number = _number.text.replaceAll(RegExp(r'\s'), '');
    final parts = _expiry.text.split(RegExp(r'[/\-]'));
    if (number.length < 13 || parts.length != 2 || _cvv.text.length < 3 || _name.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all card details correctly.');
      return;
    }
    final month = int.tryParse(parts[0]);
    var year = int.tryParse(parts[1]);
    if (month == null || year == null) {
      setState(() => _error = 'Invalid expiry date.');
      return;
    }
    if (year < 100) year += 2000;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(walletProvider.notifier).saveCard(
            cardNumber: number,
            expiryMonth: month,
            expiryYear: year,
            cvv: _cvv.text.trim(),
            cardholderName: _name.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the card.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(widget.hasCard ? 'Change card' : 'Add your card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _number,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Card number', hintText: '4966 0000 0000 0000'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiry,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Expiry', hintText: 'MM/YY'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'CVV', hintText: '123'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: "Cardholder's name"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: colors.error, fontSize: 12.5)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.hasCard ? 'Change card' : 'Save card'),
        ),
      ],
    );
  }
}
