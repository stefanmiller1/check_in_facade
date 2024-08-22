part of check_in_facade;

@LazySingleton(as: SStripeFacade)
class StripeFacade implements SStripeFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseFunctions _firebaseFunctions;


  StripeFacade(this._firebaseFunctions, this._fireStore);


  @override
  Future<Either<PaymentMethodValueFailure, StringStringItems>> processAndConfirmPaymentAsDirectCharge({
  required UserProfileModel userProfile,
  required UniqueId reservationId,
  required UniqueId listingId,
  required String? listingOwnerStripeId,
  required String amount,
  required String currency,
  required String? paymentMethod,
  required String? description,
  })  async {

    late String? customerId;
    final String numberOnlyAmount = amount.split('.').join("");

    customerId = userProfile.stripeCustomerId;

    /// create new reservation payment intent
    final functionRef = _firebaseFunctions.httpsCallable('create_new_reservation_payment_intent');


    try {

      if (listingOwnerStripeId == null) {
        return left(const PaymentMethodValueFailure.ownerDoesNotHaveAccount());
      }

      /// 1. Create Customer if not one already
      if (customerId == null) {
        /// create new customer
        final customerFunctionRef = _firebaseFunctions.httpsCallable('create_new_customer_stripe_account');
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
        'listingStripeAccount': listingOwnerStripeId,
        'reservationId' : reservationId.getOrCrash(),
        'listingId': listingId.getOrCrash(),
        'customerId': customerId,
        'holderEmail': userProfile.emailAddress.getOrCrash(),
        'amount': int.parse(numberOnlyAmount).toInt(),
        'fee': (int.parse(numberOnlyAmount) * CICOBuyerPercentageFee).toInt(),
        'currency': NumberFormat.simpleCurrency(locale: currency).currencyName?.toLowerCase(),
        'name': userProfile.legalName.value.fold((l) => '', (r) => r),
        'includeInvoice': true,
        'description': description
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
                merchantDisplayName: 'CICO',
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

        } on stripe.StripeException catch (e) {
          return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.error.message ?? 'error'));
        } catch (e) {
          return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
        }
      }


      return right(StringStringItems(
        stringItemOne: responseData.data['clientSecret'],
        stringItemTwo: responseData.data['paymentIntent']
      ));
    } on stripe.StripeException catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }
  }


  @override
  Future<Either<PaymentMethodValueFailure, List<PaymentIntent>>> processAndHoldPayment({
    required UserProfileModel userProfile,
    required String? stripeSellerAccountId,
    required UniqueId activityId,
    required List<MVBoothPayments> amounts,
    required String currency,
    required String paymentMethod,
    required String? description,
    required StripeTaxRateDetails? taxRateDetail,
    required String? taxCalculationId
  }) async {

    late List<PaymentIntent> paymentIntents = [];
    late double taxPercentage = (taxRateDetail != null) ? retrieveDoubleTaxNumber(taxRateDetail.percentageDecimal) : CICOTaxesFee;
    late String? customerId;

    try {

      if (stripeSellerAccountId == null) {
        return left(const PaymentMethodValueFailure.ownerDoesNotHaveAccount());
      }

      // Retrieve the current user's document
      final userDocRef = _fireStore.collection('users').doc(userProfile.userId.getOrCrash());
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        customerId = userDoc.data()?['stripeCustomerId'];
      }

      /// 1. Create Customer if not one already
      if (customerId == null) {
        /// create new customer
        final customerFunctionRef = _firebaseFunctions.httpsCallable('create_new_customer_stripe_account');
        final userDoc = await _fireStore.userDocument();
        final customerResponseData  = await customerFunctionRef.call(<String, dynamic>{
          'email': userProfile.emailAddress.getOrCrash(),
          'name': userProfile.legalName.getOrCrash()
        });

        final Map<String, dynamic> customerAccountId = {'stripeCustomerId': customerResponseData.data['customerId']};
        await userDoc.update(customerAccountId);
        customerId = customerResponseData.data['customerId'];
      }


      /// create new on hold payment intent
      final functionRef = _firebaseFunctions.httpsCallable('create_on_hold_payment_intent');

      for (MVBoothPayments boothPayment in amounts.where((e) => e.selectedId != null).toList()) {

      final int amount = (boothPayment.fee ?? 0) * 100;
      final totalTaxAmount = (amount * taxPercentage).toInt();
      final buyerFee = (amount * CICOBuyerPercentageFee).toInt();
      final buyerFeeTaxAmount = (buyerFee * taxPercentage).toInt();
      final sellerFee = (amount * CICOSellerPercentageFee).toInt();
      final sellerFeeTaxAmount = (sellerFee * taxPercentage).toInt();


      /// 2. Call API to create paymentIntent with paymentMethod id, Customer id and Reservation details
      final responseData = await functionRef.call(<String, dynamic>{
        'paymentMethod': paymentMethod,
        'stripeSellerAccountId': stripeSellerAccountId,
        'activityId' : activityId.getOrCrash(),
        'itemId': boothPayment.selectedId!.getOrCrash(),
        'customerId': customerId,
        'stripeBuyerEmail': userProfile.emailAddress.getOrCrash(),
        'amount': amount + totalTaxAmount,
        'buyerFee': buyerFee + buyerFeeTaxAmount,
        'sellerFee': sellerFee + sellerFeeTaxAmount,
        'currency': NumberFormat.simpleCurrency(locale: currency).currencyName?.toLowerCase(),
        'name': userProfile.legalName.value.fold((l) => '', (r) => r),
        'description': description,
        'taxCalculationId': taxCalculationId,
        }
      );

      if (responseData.data['error'] != null) {
        return left(PaymentMethodValueFailure.paymentServerError(failedValue: responseData.data['error']));
      }

      paymentIntents.add(PaymentIntent(
          id: responseData.data['paymentIntent'],
          client_secret: responseData.data['client_secret'],
          payment_method: CardItem(paymentId: paymentMethod, cardDetails: CardDetails.empty()),
          created_at: DateTime.now().millisecondsSinceEpoch,
          amount: amount,
          amount_taxed: totalTaxAmount,
          seller_fee_amount: sellerFee,
          seller_fee_amount_taxed: sellerFeeTaxAmount,
          buyer_fee_amount: buyerFee,
          buyer_fee_amount_taxed: buyerFeeTaxAmount,
          itemId: boothPayment.selectedId!.getOrCrash(),
          currency: NumberFormat.simpleCurrency(locale: currency).currencyName?.toLowerCase(),
          stripe_tax_detail: taxRateDetail,
          metaData: {
            'itemId': boothPayment.selectedId!.getOrCrash(),
            },
          )
        );
      }

      if (paymentIntents.isEmpty) {
        return left(const PaymentMethodValueFailure.paymentServerError(failedValue: 'no payments were made'));
      }

      return right(paymentIntents);
    } on stripe.StripeException catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }
  }



  @override
  Future<Either<PaymentMethodValueFailure, List<PaymentIntent>>> processAndCapturePayments({required List<PaymentIntent> payments}) async {

    late List<PaymentIntent> paymentIntents = [];

    try {

      /// create new on hold payment intent
      final functionRef = _firebaseFunctions.httpsCallable('capture_customer_payment_intent');

      for (PaymentIntent payment in payments) {
        final responseData = await functionRef.call(<String, dynamic>{
          'paymentIntentId': payment.id,
          'capture_amount': payment.amount,
        });

        if (responseData.data['error'] != null) {
          return left(PaymentMethodValueFailure.paymentServerError(failedValue: responseData.data['error']));
        }

        PaymentIntent newPayment = payment;

        newPayment = newPayment.copyWith(
          id: responseData.data['paymentIntent']['id'],
          client_secret: responseData.data['paymentIntent']['client_secret'],
          created_at: DateTime.now().millisecondsSinceEpoch,
          amount: responseData.data['paymentIntent']['amount'],
          status: responseData.data['paymentIntent']['status'],
        );


        paymentIntents.add(
            newPayment
        );
      }

      if (paymentIntents.isEmpty) {
        return left(const PaymentMethodValueFailure.paymentServerError(failedValue: 'no payments were captured'));
      }

      return right(paymentIntents);
    } on stripe.StripeException catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }
  }



  @override
  Future<Either<PaymentMethodValueFailure, List<PaymentIntent>>> cancelPaymentIntent({required List<PaymentIntent> payments}) async {

    late List<PaymentIntent> paymentIntents = [];
    final paymentMethodFunctionRef = _firebaseFunctions.httpsCallable('cancel_customer_payment_intent');


    try {

      for (PaymentIntent payment in payments) {

        final responseData = await paymentMethodFunctionRef.call(<String, dynamic>{
          'paymentIntentId': payment.id
        });

        /// 4. return payment results
        if (responseData.data['error'] != null) {
          return left (PaymentMethodValueFailure.paymentCaptureFailure(failure: payment));
        }

        PaymentIntent newPayment = payment;

        newPayment = newPayment.copyWith(
          id: responseData.data['paymentIntent']['id'],
          client_secret: responseData.data['paymentIntent']['client_secret'],
          created_at: DateTime.now().millisecondsSinceEpoch,
          amount: responseData.data['paymentIntent']['amount'],
          status: responseData.data['paymentIntent']['status'],
        );

        paymentIntents.add(
            newPayment
        );
      }


      if (paymentIntents.isEmpty) {
        return left(PaymentMethodValueFailure.paymentServerError(failedValue: 'no payments were cancelled'));
      }

      return right(paymentIntents);
    } on stripe.StripeException catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    } catch (e) {
      return left(PaymentMethodValueFailure.paymentServerError(failedValue: e.toString()));
    }
  }


  @override
  Future<Either<PaymentMethodValueFailure, List<StripeRefundModel>>> refundExistingStripePayment({required List<PaymentIntent> payments, required String? refundAmount}) async {
    final paymentMethodFunctionRef = _firebaseFunctions.httpsCallable('create_new_refund_payment_intent');
    late List<StripeRefundModel> paymentRefunds = [];

    try {


      for (PaymentIntent payment in payments) {

        final responseData = await  paymentMethodFunctionRef.call(<String, dynamic>{
          'paymentIntent': payment.id,
          'amount': refundAmount,
        });

        print(responseData.data);
        /// 4. return payment results
        if (responseData.data['error'] != null) {
          return left (PaymentMethodValueFailure.paymentServerError(failedValue: responseData.data['error']));
        }

        late StripeRefundModel newRefund = const StripeRefundModel();

        var stripeRefundModel = newRefund.copyWith(
          id: responseData.data['refund']['id'],
          object: responseData.data['refund']['object'],
          amount: responseData.data['refund']['amount'],
          balance_transaction: responseData.data['refund']['balance_transaction'],
          charge: responseData.data['refund']['charge'],
          created: responseData.data['refund']['created'],
          currency: responseData.data['refund']['currency'],
          paymentIntent: responseData.data['refund']['paymentIntent'],
          reason: 'requested by the payer',
          receipt_number: responseData.data['refund']['receipt_number'],
          status: responseData.data['refund']['status'],
        );

        newRefund = stripeRefundModel;

        paymentRefunds.add(
            newRefund
        );
      }

      if (paymentRefunds.isEmpty) {
        return left(PaymentMethodValueFailure.paymentServerError(failedValue: 'no payments were refunded'));
      }

      return right(paymentRefunds);
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
        return left (PaymentMethodValueFailure.paymentServerError(failedValue: responseData.data['error']));
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

    print('oookay');
    try {

      late String? customerId;
      customerId = userProfile.stripeCustomerId;

      print(customerId);

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


      await paymentFunctionRef.call(<String, dynamic>{
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
          'last_name': profile.legalSurname.value.fold((l) => null, (r) => r),
        }
      );

      if (responseData.data['accountId'] is String) {
        final Map<String, dynamic> stripeAccount = {
          'stripeAccountId': responseData.data['accountId']
        };
        await userDoc.update(stripeAccount);
      }
      if (!(await canLaunchUrl(Uri.parse(responseData.data['url'] as String)))) {
        return left(const AuthFailure.exceptionError('sorry, could not open url'));
      }

      launchUrl(Uri.parse(responseData.data['url'] as String));

      return right(unit);
    } catch (e) {
      return left(AuthFailure.exceptionError(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateStripeAccountSettingsLink({
    required UserProfileModel profile,
  }) async {


    final functionRef = _firebaseFunctions.httpsCallable('create_update_stripe_account_link');

    try {

      final responseData = await functionRef.call(<String, dynamic>{
        'stripeAccountId': profile.stripeAccountId,
        }
      );

      print(responseData.data);
      if (responseData.data['error'] != null) {
        return left(AuthFailure.exceptionError(responseData.data['error'] as String));
      }

      if (!(await canLaunchUrl(Uri.parse(responseData.data['url'] as String)))) {
        return left(const AuthFailure.exceptionError('sorry, could not open url'));
      }

      launchUrl(Uri.parse(responseData.data['url'] as String));

      return right(unit);
    } catch (e) {
      print(e);
      return left(AuthFailure.exceptionError(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteStripeConnectAccountLink({
    required UserProfileModel profile,
  }) async {


    final functionRef = _firebaseFunctions.httpsCallable('delete_stripe_connect_account');

    try {

      final responseData = await functionRef.call(<String, dynamic>{
        'stripeAccountId': profile.stripeAccountId,
        'currentUserId': profile.userId.getOrCrash()
        }
      );

      if (responseData.data['success'] == true) {
        return right(unit);
      }

      return left(const AuthFailure.exceptionError('sorry, we could not delete this account'));
    } catch (e) {
      return left(AuthFailure.exceptionError(e.toString()));
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

}

class StripeInstanceFacade {

  StripeInstanceFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;

  // Get proper [FirebaseFunctions] instance.
  FirebaseFunctions getFirebaseFunctions() => FirebaseFunctions.instance;

  static final StripeInstanceFacade instance = StripeInstanceFacade._privateConstructor();

  Future<StripeTaxCalculation> createTaxCalculation({
    required StripeBusinessAddress stripeSellerAddress,
    required String currency,
    required int amount,
    required int serviceFee,
  }) async {

    final response = getFirebaseFunctions().httpsCallable('create_stripe_tax_calculation');

    try {


      final responseData = await response.call(<String, dynamic>{
        'stripeSellerAddress': {
          'city': stripeSellerAddress.city,
          'country': stripeSellerAddress.country,
          'line1': stripeSellerAddress.line1,
          'line2': stripeSellerAddress.line2,
          'postal_code': stripeSellerAddress.postal_code,
          'state': stripeSellerAddress.state,
        },
        'currency': NumberFormat.simpleCurrency(locale: currency).currencyName?.toLowerCase(),
        'amount': amount,
        'serviceFee': serviceFee,
      });

        if (responseData.data['error'] != null) {
          return Future.error('sorry, something went wrong, ${responseData.data['error']}');
        }

      return parseTaxCalculation(responseData.data['taxCalculation']);
    } catch (e) {
      return Future.error(e);
    }
  }

  StripeTaxCalculation parseTaxCalculation(Map<String, dynamic> json) {
    return StripeTaxCalculation(
      id: json['id'],
      amountTotal: json['amount_total'],
      currency: json['currency'],
      taxBreakdown: (json['tax_breakdown'] as List<dynamic>).map((item) {
        return StripeTaxBreakdown(
          amount: item['amount'],
          inclusive: item['inclusive'],
          stripeTaxRateDetails: StripeTaxRateDetails(
            country: item['tax_rate_details']['country'],
            percentageDecimal: item['tax_rate_details']['percentage_decimal'],
            state: item['tax_rate_details']['state'],
            taxType: item['tax_rate_details']['tax_type'],
          ),
          taxAbilityReason: item['taxability_reason'],
          taxableAmount: item['taxable_amount'],
        );
      }).toList(),
      taxAmountInclusive: json['tax_amount_inclusive'],
      taxAmountExclusive: json['tax_amount_exclusive'],
    );
  }

}


