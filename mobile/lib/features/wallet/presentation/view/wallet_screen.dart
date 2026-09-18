import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/referral/presentation/providers/referral_providers.dart';
import 'package:zennyt/features/wallet/domain/entities/wallet.dart';
import 'package:zennyt/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:zennyt/features/wallet/presentation/widgets/card_form_sheet.dart';
import 'package:zennyt/features/wallet/presentation/widgets/payment_card_view.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Portefeuille (maquettes 114/118) : la carte dessinée comme une vraie carte,
/// le solde et ses actions, puis l'activité groupée par jour.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: CustomAppBar(title: 'Wallet', onBack: () => context.pop()),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refresh();
          await ref.read(walletTransactionsProvider.future);
        },
        child: walletAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _WalletError(
            onRetry: () => ref.read(walletProvider.notifier).refresh(),
          ),
          data: (wallet) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: wallet.card == null
                      ? _AddCardPlaceholder(
                          onTap: () => showCardFormSheet(context, hasCard: false),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PaymentCardView.saved(
                              key: const ValueKey('wallet-card'),
                              brand: wallet.card!.brand,
                              last4: wallet.card!.last4,
                              holder: wallet.card!.cardholderName,
                              expiry: wallet.card!.expiryDisplay,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                key: const ValueKey('wallet-change-card'),
                                onPressed: () => showCardFormSheet(context, hasCard: true),
                                icon: AppIcon(
                                  HugeIcons.strokeRoundedCreditCardChange,
                                  color: colors.primary,
                                  size: 18,
                                ),
                                label: const Text('Change card'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),
              _BalancePanel(
                wallet: wallet,
                onWithdraw: () => _withdraw(context, ref, wallet),
                onShareLink: () => _shareLink(context, ref),
              ),
              const SizedBox(height: 28),
              Text(
                'Activity',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              transactionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text('Could not load your activity.', style: TextStyle(color: colors.error)),
                ),
                data: (transactions) => transactions.isEmpty
                    ? const _EmptyActivity()
                    : _TransactionList(transactions: transactions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareLink(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final link = await ref.read(referralLinkProvider.future);
      await Clipboard.setData(ClipboardData(text: link.url));
      messenger.showSnackBar(const SnackBar(content: Text('Referral link copied')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not get your link.')));
    }
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref, Wallet wallet) async {
    if (wallet.card == null) {
      await showCardFormSheet(context, hasCard: false);
      return;
    }
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(wallet: wallet),
    );
    if (amount == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(walletProvider.notifier).withdraw(amount);
      messenger.showSnackBar(SnackBar(
        content: Text('${Wallet.formatAmount(amount, wallet.currency)} is on its way to your card'),
      ));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      children: [
        const SizedBox(height: 120),
        AppIcon(HugeIcons.strokeRoundedWallet01, color: colors.textSecondary, size: 40),
        const SizedBox(height: 12),
        Text(
          'Could not load your wallet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        Center(child: TextButton(onPressed: onRetry, child: const Text('Retry'))),
      ],
    );
  }
}

/// Emplacement de carte vide, au format d'une carte, en pointillés.
class _AddCardPlaceholder extends StatelessWidget {
  const _AddCardPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: PaymentCardView.aspectRatio,
      child: Material(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('wallet-add-card'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: CustomPaint(
            painter: _DashedBorderPainter(color: colors.primary.withValues(alpha: 0.5)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AppIcon(
                          HugeIcons.strokeRoundedCreditCardAdd,
                          color: colors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a card',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Needed to withdraw your earnings',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1),
        const Radius.circular(18),
      ));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.wallet,
    required this.onWithdraw,
    required this.onShareLink,
  });

  final Wallet wallet;
  final VoidCallback onWithdraw;
  final VoidCallback onShareLink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              wallet.balanceDisplay,
              key: const ValueKey('wallet-balance'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Earned from referrals and rewards',
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('wallet-withdraw'),
                  onPressed: onWithdraw,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    minimumSize: const Size.fromHeight(50),
                    // Le thème ajoute 24 px de chaque côté : trop pour deux boutons
                    // côte à côte, le libellé passait à la ligne.
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const AppIcon(
                    HugeIcons.strokeRoundedArrowDownLeft01,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Withdraw',
                      maxLines: 1, softWrap: false, overflow: TextOverflow.fade,
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShareLink,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.border),
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: AppIcon(HugeIcons.strokeRoundedLink01, color: colors.primary, size: 18),
                  label: const Text('Share link',
                      maxLines: 1, softWrap: false, overflow: TextOverflow.fade,
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          AppIcon(HugeIcons.strokeRoundedInvoice01, color: colors.textSecondary, size: 30),
          const SizedBox(height: 10),
          Text(
            'No activity yet',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Invite friends to start earning rewards.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Écritures groupées par jour (« Today », « Yesterday », puis la date).
class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<WalletTransaction> transactions;

  static String _dayLabel(DateTime? date) {
    if (date == null) return 'Earlier';
    final local = date.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(local);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.yMMMd().format(local);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final groups = <String, List<WalletTransaction>>{};
    for (final t in transactions) {
      groups.putIfAbsent(_dayLabel(t.createdAt), () => []).add(t);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 64, color: colors.divider),
                  _TransactionTile(transaction: entry.value[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, tint) = switch (transaction.kind) {
      WalletTransactionKind.credit => (HugeIcons.strokeRoundedGift, const Color(0xFF16A34A)),
      WalletTransactionKind.withdrawal => (HugeIcons.strokeRoundedBank, const Color(0xFF4F6BED)),
      WalletTransactionKind.debit => (HugeIcons.strokeRoundedArrowUpRight01, const Color(0xFFEF4444)),
    };
    final positive = transaction.amountCents >= 0;
    final time = transaction.createdAt == null
        ? null
        : DateFormat.Hm().format(transaction.createdAt!.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: AppIcon(icon, color: tint, size: 19)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
                if (time != null)
                  Text(time, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            transaction.amountDisplay,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: positive ? const Color(0xFF16A34A) : colors.textPrimary,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Retrait : montant décimal à 2 chiffres max, raccourcis 25 % / 50 % / Max,
/// jamais au-delà du solde.
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.wallet});

  final Wallet wallet;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_amount.text.replaceAll(',', '.'));

  String? get _error {
    final v = _value;
    if (_amount.text.isEmpty) return null;
    if (v == null || v <= 0) return 'Enter an amount above 0';
    if (v > widget.wallet.balance + 1e-9) return 'You only have ${widget.wallet.balanceDisplay}';
    return null;
  }

  bool get _valid => _amount.text.isNotEmpty && _error == null;

  void _preset(double fraction) {
    final v = (widget.wallet.balance * fraction * 100).floor() / 100;
    _amount.text = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = widget.wallet.card!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Withdraw',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To ${card.brand} ${card.masked} · available ${widget.wallet.balanceDisplay}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('withdraw-amount'),
                  controller: _amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}([.,]\d{0,2})?')),
                  ],
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: '${widget.wallet.currency} ',
                    errorText: _error,
                    filled: true,
                    fillColor: colors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (label, fraction) in const [('25%', 0.25), ('50%', 0.5), ('Max', 1.0)])
                      ActionChip(
                        label: Text(label),
                        onPressed: widget.wallet.balance > 0 ? () => _preset(fraction) : null,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: const ValueKey('withdraw-confirm'),
                    onPressed: _valid ? () => Navigator.of(context).pop(_value) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Withdraw',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
