part of check_in_facade;

@LazySingleton(as: SStripeFacade)
class StripeFacade implements SStripeFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseFunctions _firebaseFunctions;


  StripeFacade(this._firebaseFunctions, this._fireStore);


  @override
  Future<Either<PaymentMethodValueFailure, StringStringItems>> processAndConfirmPaymentAsDirectCharge({
  required UserProfileModel userProfile,
  required ReservationItem reservationItem,
  required String amount,
  required String currency,
  required String? paymentMethod,
  })  async {

    late String? customerId;
    final numberOnlyAmount = amount.split('.').join("");
    customerId = userProfile.stripeCustomerId;
    /// create new customer
    final customerFunctionRef = _firebaseFunctions.httpsCallable('create_new_customer_stripe_account');
    /// create new reservation payment intent
    final functionRef = _firebaseFunctions.httpsCallable('create_new_reservation_payment_intent');


    try {


      /// 1. Create Customer if not one already
      if (customerId == null) {
        final userDoc = await _fireStore.userDocument();
        final customerResponseData  = await customerFunctionRef.call(<String, dynamic>{
          'email': userProfile.emailAddress.getOrCrash(),
          'name': userProfile.legalName.getOrCrash()
        });

        final Map<String, dynamic> customerAccountId = {'stripeCustomerId': customerResponseData.data['customerId']};
        await userDoc.update(customerAccountId);
        customerId = customerResponseData.data['customerId'];
      }


      /// 2. Call API to create paymentIntent with paymentMethod id, Customer id and Reservation details
      final responseData = await functionRef.call(<String, dynamic>{
        'paymentMethod': paymentMethod,
        'listingStripeAccount': 'acct_1Lfkm4BRv4KcJPVD',
        'reservationId' : reservationItem.reservationId.getOrCrash(),
        'listingId': reservationItem.instanceId.getOrCrash(),
        'customerId': customerId,
        'holderEmail': userProfile.emailAddress.getOrCrash(),
        'amount': int.parse(numberOnlyAmount).toInt(),
        'fee': (int.parse(numberOnlyAmount) * CICOReservationPercentageFee).toInt(),
        'currency': currency,
        'name': userProfile.legalName.value.fold((l) => '', (r) => r),
        }
      );


      /// 4. return payment results
      if (responseData.data['error'] != null) {
        return left (PaymentMethodValueFailure.paymentServerError(failedValue: responseData.data['error']));
      }

      /// 4. return payment results
      if (responseData.data['payment_failed'] != null) {
        return left (const PaymentMethodValueFailure.insufficientFunds());
      }

      /// if requires actions
      if (responseData.data['clientSecret'] != null && responseData.data['requiresAction'] == true) {
        return left (PaymentMethodValueFailure.requiresMoreAction(responseData.data['paymentIntent']));
      }


      if (!(kIsWeb)) {

        try {

          await stripe.Stripe.instance.initPaymentSheet(
              paymentSheetParameters: stripe.SetupPaymentSheetParameters(
                applePay: stripe.PaymentSheetApplePay(
                  merchantCountryCode: currency
                ),
                merchantDisplayName: 'CICO Check Out',
                paymentIntentClientSecret: responseData.data['clientSecret'],
                customerEphemeralKeySecret: responseData.data['ephemeralKey'],
                customerId: customerId,
                billingDetails: stripe.BillingDetails(
                  name: userProfile.legalName.getOrCrash(),
                  phone: userProfile.contactPhones?.nsn,
              ),
            )
          );

          await stripe.Stripe.instance.presentPaymentSheet();
        } catch (e) {
          return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
        }
      }


      return right(StringStringItems(
        stringItemOne: responseData.data['clientSecret'],
        stringItemTwo: responseData.data['paymentIntent']
      ));
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }

  }

  @override
  Future<Either<PaymentMethodValueFailure, StringStringItems>> confirmExistingPaymentIntent({required String paymentIntentId}) async {

    final paymentMethodFunctionRef = _firebaseFunctions.httpsCallable('confirm_customer_payment_intent');


    try {

      final responseData = await  paymentMethodFunctionRef.call(<String, dynamic>{
        'paymentIntentId': paymentIntentId
      });

      /// 4. return payment results
      if (responseData.data['error'] != null) {
        return left (const PaymentMethodValueFailure.paymentServerError());
      }

      return right(StringStringItems(
          stringItemOne: responseData.data['paymentIntent'],
          stringItemTwo: responseData.data['clientSecret']));
    } catch (e) {
      return left(const PaymentMethodValueFailure.paymentServerError());
    }
  }


  @override
  Future<Either<PaymentMethodValueFailure, Unit>> createNewPaymentMethod({required UserProfileModel userProfile, required String cardToken}) async {

    /// create new card
    final paymentFunctionRef = _firebaseFunctions.httpsCallable('create_new_stripe_customer_card');
    /// in case customer does not exist create new customer
    final customerFunctionRef = _firebaseFunctions.httpsCallable('create_new_customer_stripe_account');

    try {

      late String? customerId;
      customerId = userProfile.stripeCustomerId;

      if (customerId == null) {
        final userDoc = await _fireStore.userDocument();
        final customerResponseData  = await customerFunctionRef.call(<String, dynamic>{
          'email': userProfile.emailAddress.getOrCrash(),
          'name': userProfile.legalName.getOrCrash()
        });

        final Map<String, dynamic> customerAccountId = {'stripeCustomerId': customerResponseData.data['customerId']};
        await userDoc.update(customerAccountId);
        customerId = customerResponseData.data['customerId'];
      }


      final responseData = await paymentFunctionRef.call(<String, dynamic>{
        'customerId': customerId,
        'source' : cardToken
      });

      return right(unit);
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }
  }


  @override
  Future<Either<PaymentMethodValueFailure, Unit>> deletePaymentMethod({required UserProfileModel userProfile, required List<String> cardItem}) async {

      final deleteCardFunctionRef = _firebaseFunctions.httpsCallable('delete_stripe_customer_card');

    try {

      for (String cardId in cardItem) {
          await deleteCardFunctionRef.call(<String, dynamic>{
           'customerId': userProfile.stripeCustomerId,
           'cardId': cardId
          });
      }

      return right(unit);
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }
  }


  Future<Map<String, dynamic>> fetchPaymentIntentClientSecret({required String currency, required String amount}) async {
    final url = Uri.parse('');
    final response = await http.post(
      url,
      headers: {
        'Context-Type': 'applications/json'
      },
      body: json.encode({
        'currency': currency,
        'amount': amount,
        'payment_method_type': ['card'],
        'request_three_d_secure': 'any'
      }),
    );
    return json.decode(response.body);
  }



  /// Handle Vendor Stripe onCall Functions
  ///create new stripe account for onBoarding
  @override
  Future<Either<AuthFailure, Unit>> createOnBoardingStripeAccountLink({
  required UserProfileModel profile,
}) async {

    final functionRef = _firebaseFunctions.httpsCallable('create_onboarding_stripe_account_link');

    try {

      final userDoc = await _fireStore.userDocument();
      final responseData = await functionRef.call(<String, dynamic>{
          'stripeAccountId': profile.stripeAccountId,
          'email': profile.emailAddress.getOrCrash(),
          'first_name': profile.legalName.value.fold((l) => null, (r) => r),
        }
      );


      final Map<String, dynamic> stripeAccount = {'stripeAccountId': responseData.data['accountId']};
      await userDoc.update(stripeAccount);

      if (!(await canLaunchUrl(Uri.parse(responseData.data['url'] as String)))) {
        return left(AuthFailure.serverError());
      }

      launchUrl(Uri.parse(responseData.data['url'] as String));

      return right(unit);
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> presentStripeAccountWithLoginLink({required UserProfileModel profile}) async {

    final functionRef = _firebaseFunctions.httpsCallable('on_redirect_to_stripe_account');

    try {

      final responseData = await functionRef.call(<String, dynamic>{
          'stripeAccountId': profile.stripeAccountId
      });


      if (!(await canLaunchUrl(Uri.parse(responseData.data['url'] as String)))) {
        return left(AuthFailure.serverError());
      }

      launchUrl(Uri.parse(responseData.data['url'] as String));

      return right(unit);
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }


  @override
  Stream<Either<AuthFailure, String>> watchStripePaymentSetupIntent({required String setupIntent}) {
    // TODO: implement watchStripePaymentSetupIntent
    throw UnimplementedError();
  }


  @override
  Future<Either<PaymentMethodValueFailure, StringStringItems>> refundExistingStripePayment({required String paymentIntent, required String refundAmount}) async {
    final paymentMethodFunctionRef = _firebaseFunctions.httpsCallable('create_new_refund_payment_intent');


    try {

      final responseData = await  paymentMethodFunctionRef.call(<String, dynamic>{
        'paymentIntent': paymentIntent,
        'amount': int.parse(refundAmount.split(' ')[1]) * 100
      });


      /// 4. return payment results
      if (responseData.data['error'] != null) {
        return left (PaymentMethodValueFailure.paymentServerError(failedValue: responseData.data['error']));
      }

      return right(StringStringItems(stringItemOne: responseData.data['refund_id'], stringItemTwo: ''));
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }

  }


}