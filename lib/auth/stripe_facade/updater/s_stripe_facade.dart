part of check_in_facade;

abstract class SStripeFacade {

  /// create account link for new or existing accountId - present account link url
  Future<Either<AuthFailure, Unit>> createOnBoardingStripeAccountLink({
    required UserProfileModel profile});

  /// present authenticated Stripe account dashboard with Stripe Login Link
  Future<Either<AuthFailure, Unit>> presentStripeAccountWithLoginLink({
    required UserProfileModel profile
  });

  Future<Either<AuthFailure, Unit>> updateStripeAccountSettingsLink({
    required UserProfileModel profile
  });

  Future<Either<AuthFailure, Unit>> deleteStripeConnectAccountLink({
    required UserProfileModel profile
  });

  /// create new stripe payment
  Future<Either<PaymentMethodValueFailure, StringStringItems>> processAndConfirmPaymentAsDirectCharge({
    required UserProfileModel userProfile,
    required UniqueId reservationId,
    required UniqueId listingId,
    required String? listingOwnerStripeId,
    required String amount,
    required String currency,
    required String? paymentMethod,
    required String? description,
  });

  /// create on hold stripe payment
  Future<Either<PaymentMethodValueFailure, List<PaymentIntent>>> processAndHoldPayment({
    required UserProfileModel userProfile,
    required String? stripeSellerAccountId,
    required UniqueId activityId,
    required List<MVBoothPayments> amounts,
    required String currency,
    required DiscountCode? discount,
    required CardItem paymentMethod,
    required String? description,
    required StripeTaxRateDetails? taxRateDetail,
    required String? taxCalculationId
});

  /// capture payment intent
  Future<Either<PaymentMethodValueFailure, List<PaymentIntent>>> processAndCapturePayments({
    required List<PaymentIntent> payments
  });

  /// cancel on hold payment intent
  Future<Either<PaymentMethodValueFailure, List<PaymentIntent>>> cancelPaymentIntent({
    required List<PaymentIntent> payments
  });

  /// confirm Stripe payment intent
  Future<Either<PaymentMethodValueFailure, StringStringItems>> confirmExistingPaymentIntent({
    required String paymentIntentId
  });

  /// refund existing stripe payment
  Future<Either<PaymentMethodValueFailure, List<StripeRefundModel>>> refundExistingStripePayment({
    required List<PaymentIntent> payments,
    required String? refundAmount
  });

  /// create and save ne Stripe card payment method
  Future<Either<PaymentMethodValueFailure, Unit>> createNewPaymentMethod({
    required UserProfileModel userProfile,
    required String cardToken,
  });

  /// delete Stripe card payment method
  Future<Either<PaymentMethodValueFailure, Unit>> deletePaymentMethod({
    required UserProfileModel userProfile,
    required List<String> cardItem,
  });

  /// watch stripe payment status intent
  Stream<Either<AuthFailure, String>> watchStripePaymentSetupIntent({required String setupIntent});


}