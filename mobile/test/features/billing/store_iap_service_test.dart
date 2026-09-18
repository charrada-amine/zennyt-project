import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:zennyt/features/billing/data/store_iap_service.dart';
import 'package:zennyt/features/billing/domain/entities/billing.dart';
import 'package:zennyt/features/billing/domain/repositories/billing_repository.dart';

class _Iap extends Fake implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  Object? buyError;
  bool buyResult = true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    if (buyError != null) throw buyError!;
    return buyResult;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) {
    return buyNonConsumable(purchaseParam: purchaseParam);
  }
}

class _Repository extends Fake implements BillingRepository {
  int verificationCalls = 0;
  Object? verifyError;
  Completer<void>? verificationGate;

  @override
  Future<void> verifyPurchase({
    required String productId,
    required String store,
    required String receipt,
    required String transactionId,
  }) async {
    verificationCalls++;
    if (verificationGate != null) await verificationGate!.future;
    final error = verifyError;
    if (error != null) throw error;
  }
}

BillingPlan _plan() => const BillingPlan(
      code: 'video_interview_single',
      productId: 'video_interview_single',
      name: 'Video-interview',
      description: '',
      priceCents: 999,
      currency: 'EUR',
      period: 'NONE',
      popular: false,
    );

ProductDetails _product() => ProductDetails(
      id: 'video_interview_single',
      title: 'Video-interview',
      description: '',
      price: '9.99€',
      rawPrice: 9.99,
      currencyCode: 'EUR',
    );

PurchaseDetails _purchase({
  String id = 'transaction-1',
  String productID = 'video_interview_single',
  PurchaseStatus status = PurchaseStatus.purchased,
}) =>
    PurchaseDetails(
      purchaseID: id,
      productID: productID,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'receipt-$id',
        source: 'app_store',
      ),
      transactionDate: '1',
      status: status,
    )..pendingCompletePurchase = true;

void main() {
  test('successful verify completes the purchase', () async {
    final iap = _Iap();
    final repository = _Repository();
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    final outcomeFuture = service.purchase(_plan(), _product());
    iap.events.add([_purchase()]);
    final outcome = await outcomeFuture;

    expect(outcome, PurchaseOutcome.purchased);
    expect(repository.verificationCalls, 1);
    expect(iap.completed, hasLength(1));
    expect(iap.completed.single.productID, 'video_interview_single');
  });

  test('backend failure leaves transaction pending and surfaces the error',
      () async {
    final iap = _Iap();
    final repository = _Repository()..verifyError = StateError('Backend down');
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    final outcomeFuture = service.purchase(_plan(), _product());
    iap.events.add([_purchase()]);

    await expectLater(outcomeFuture, throwsStateError);
    expect(repository.verificationCalls, 1);
    expect(iap.completed, isEmpty);
  });

  test('cancellation settles with PurchaseOutcome.canceled', () async {
    final iap = _Iap();
    final repository = _Repository();
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    final outcomeFuture = service.purchase(_plan(), _product());
    iap.events.add([_purchase(status: PurchaseStatus.canceled)]);
    final outcome = await outcomeFuture;

    expect(outcome, PurchaseOutcome.canceled);
    expect(repository.verificationCalls, 0);
    expect(iap.completed, hasLength(1));
  });

  test('initiation exception fails the purchase future', () async {
    final iap = _Iap()..buyError = StateError('Store unavailable');
    final repository = _Repository();
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    await expectLater(
      service.purchase(_plan(), _product()),
      throwsStateError,
    );
    expect(repository.verificationCalls, 0);
  });

  test('initiation refused by the store fails the purchase future', () async {
    final iap = _Iap()..buyResult = false;
    final repository = _Repository();
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    await expectLater(
      service.purchase(_plan(), _product()),
      throwsStateError,
    );
    expect(repository.verificationCalls, 0);
  });

  test('paywall only succeeds after verification as practical', () async {
    final iap = _Iap();
    final repository = _Repository()..verifyError = StateError('Backend down');
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    final outcomeFuture = service.purchase(_plan(), _product());
    iap.events.add([_purchase(status: PurchaseStatus.canceled)]);
    final canceledOutcome = await outcomeFuture;
    expect(canceledOutcome, isNot(PurchaseOutcome.purchased));

    repository.verifyError = null;
    final verifiedFuture = service.purchase(_plan(), _product());
    iap.events.add([_purchase(id: 'transaction-2')]);
    final verifiedOutcome = await verifiedFuture;
    expect(verifiedOutcome, PurchaseOutcome.purchased);
    expect(iap.completed.map((p) => p.productID), everyElement('video_interview_single'));
    expect(iap.completed, isNotEmpty);
  });

  test('duplicate purchases share the pending outcome', () async {
    final iap = _Iap();
    final repository = _Repository()..verifyError = StateError('Backend down');
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);

    final firstFuture = service.purchase(_plan(), _product());
    final secondFuture = service.purchase(_plan(), _product());

    expect(identical(firstFuture, secondFuture), isTrue);
    final expectation = expectLater(firstFuture, throwsStateError);
    iap.events.add([_purchase(id: 'transaction-2')]);
    await expectation;
  });

  test('stream errors settle pending purchases', () async {
    final iap = _Iap();
    final service = StoreIapService(_Repository(), iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);
    final expectation = expectLater(
      service.purchase(_plan(), _product()), throwsStateError,
    );
    iap.events.addError(StateError('Stream disconnected'));
    await expectation;
  });

  test('dispose during verification never unlocks a purchase', () async {
    final iap = _Iap();
    final gate = Completer<void>();
    final repository = _Repository()..verificationGate = gate;
    final service = StoreIapService(repository, iap: iap)..start();
    final expectation = expectLater(
      service.purchase(_plan(), _product()), throwsStateError,
    );
    iap.events.add([_purchase()]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.verificationCalls, 1);
    service.dispose();
    await expectation;
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(iap.completed, isEmpty);
    await iap.events.close();
  });

  test('duplicate transaction deliveries are verified once', () async {
    final iap = _Iap();
    final repository = _Repository();
    final service = StoreIapService(repository, iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);
    final future = service.purchase(_plan(), _product());
    iap.events.add([_purchase(), _purchase()]);
    expect(await future, PurchaseOutcome.purchased);
    await Future<void>.delayed(Duration.zero);
    expect(repository.verificationCalls, 1);
    expect(iap.completed, hasLength(1));
  });

  test('restoration is not a new purchased outcome', () async {
    final iap = _Iap();
    final service = StoreIapService(_Repository(), iap: iap)..start();
    addTearDown(service.dispose);
    addTearDown(iap.events.close);
    final future = service.purchase(_plan(), _product());
    iap.events.add([_purchase(status: PurchaseStatus.restored)]);
    expect(await future, PurchaseOutcome.restored);
  });

  test('dispose completes pending outcomes with an error', () async {
    final iap = _Iap();
    final repository = _Repository();
    final service = StoreIapService(repository, iap: iap)..start();

    final outcomeFuture = service.purchase(_plan(), _product());
    service.dispose();

    await expectLater(outcomeFuture, throwsStateError);
  });
}
