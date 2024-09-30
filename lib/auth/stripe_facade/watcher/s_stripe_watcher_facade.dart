part of check_in_facade;

@LazySingleton(as: SStripeWatcherFacade)
class StripeWatcherFacade implements SStripeWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseFunctions _firebaseFunctions;

  StripeWatcherFacade(this._firebaseFunctions, this._fireStore);


  @override
  Stream<Either<PaymentMethodValueFailure, List<CardItem>>> watchCustomerPaymentMethod({required String customerId}) async* {

    final customerFunctionRef = _firebaseFunctions.httpsCallable('retrieve_customer_payment_methods');

    try {

        final responseData = await customerFunctionRef.call(<String, dynamic>{
          'customerId': customerId
        });

        // print(responseData.data['data'] as List);

        final List data = responseData.data['data'];
        // print(data.map((e) => CardItem(paymentId: e['id'], cardDetails: CardDetails(brand: e['card']['brand'], lastFourNumbers: lastFourNumbers, expMonth: expMonth, expiryYearDate: expiryYearDate))));

        if (data.isNotEmpty) {
          final List<CardItem> cardItems = data.map((e) => CardItem(paymentId: e['id'], cardDetails: CardDetails(brand: e['card']['brand'], lastFourNumbers: e['card']['last4'], expMonth: e['card']['exp_month'], expiryYearDate: e['card']['exp_year']))).toList();
           yield right(cardItems);
           return;
        }
        yield left(PaymentMethodValueFailure.couldNotRetrievePaymentMethod());
    } catch (e) {
      yield left(const PaymentMethodValueFailure.paymentServerError());
    }
  }

  @override
  Stream<Either<PaymentMethodValueFailure, List<PaymentIntent>>> watchCustomerPaymentIntents({required String customerId}) async* {

    final customerFunctionRef = _firebaseFunctions.httpsCallable('retrieve_customer_payment_intent_history');

    try {
      final responseData = await customerFunctionRef.call(<String, dynamic>{
        'customerId': customerId,
        'limit': 40
      });
      final List data = responseData.data['data'];

      print(data.map((e) => e));

      if (data.isNotEmpty) {

        final List<PaymentIntent> paymentItems = data.map((e) {
          // final List charges = e['charges']['data'];
          // List<CardItem?> cardItems = charges.map((charge) {
          //   if (charge['payment_method_details'] != null && charge['payment_method_details']['card'] != null) {
          //     return CardItem(
          //       paymentId: charge['payment_method'],
          //       cardDetails: CardDetails(
          //         brand: charge['payment_method_details']['card']['brand'],
          //         lastFourNumbers: charge['payment_method_details']['card']['last4'],
          //         expMonth: charge['payment_method_details']['card']['exp_month'],
          //         expiryYearDate: charge['payment_method_details']['card']['exp_year'],
          //       ),
          //     );
          //   }
          //   return null; // Return null if card details are not available
          // }).where((item) => item != null).toList();
          // final charge = charges.where((element) => element['outcome']['network_status'] == 'approved_by_network').isNotEmpty ? charges.firstWhere((element) => element['outcome']['network_status'] == 'approved_by_network') : e.;


          // print(e['charges']['data']);
          // print(charge);

          return PaymentIntent(
            id: e['id'],
            status: e['status'],
            canceled_at: e['canceled_at'],
            amount: e['amount'],
            created: e['created'],
            currency: e['currency'],
            // payment_method: CardItem(
            //     paymentId: charge['payment_method'],
            //     cardDetails: CardDetails(
            //         brand: charge['payment_method_details']['card']['brand'],
            //         lastFourNumbers: charge['payment_method_details']['card']['last4'],
            //         expMonth: charge['payment_method_details']['card']['exp_month'],
            //         expiryYearDate: charge['payment_method_details']['card']['exp_year']
            //     )
            // ),
            // itemId: e['metadata']['reservationId'],
            metaData: e['metadata'],
            // receipt_url: charge['receipt_url'],
          );
        }).toList();

        

        yield right(paymentItems);
        return;
      }

      yield left(PaymentMethodValueFailure.couldNotRetrievePaymentMethod());
    } catch (e) {
      yield left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }

  }

  @override
  Stream<Either<PaymentMethodValueFailure, List<PayoutModel>>> watchPayoutHistory() async* {

    final stripeAccountFunctionRef = _firebaseFunctions.httpsCallable('retrieve_all_payouts');

    try {

      final responseData = await stripeAccountFunctionRef.call(<String, dynamic>{
        'limit': 40
      });

      final List data = responseData.data['data'];

      if (data.isNotEmpty) {

        final List<PayoutModel> payouts = data.map((e) {
          return PayoutModel(
              id: e['id'],
              object: e['object'],
              amount: e['amount'],
              currency: e['currency'],
              balance_transaction: e['balance_transaction'],
              description: e['description'],
              destination: e['destination'],
              arrival_date: e['arrival_date'],
              created: e['created'],
              failure_code: e['failure_code'],
              failure_message: e['failure_message'],
              status: e['status'],
              method: e['method'],
              source_type: e['source_type'],
              type: e['type']
          );
        }).toList();


        yield right(payouts);
        return;
      }

      yield left(const PaymentMethodValueFailure.couldNotRetrievePaymentMethod());
    } catch (e) {
      yield left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }

  }



}