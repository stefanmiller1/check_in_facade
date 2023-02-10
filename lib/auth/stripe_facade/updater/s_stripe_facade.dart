part of check_in_facade;

abstract class SStripeFacade {

  /// create account link for new or existing accountId - present account link url
  Future<Either<AuthFailure, Unit>> createOnBoardingStripeAccountLink({
    required UserProfileModel profile});

  /// present authenticated Stripe account dashboard with Stripe Login Link
  Future<Either<AuthFailure, Unit>> presentStripeAccountWithLoginLink({
    required UserProfileModel profile
  });


  /// create new stripe payment
  Future<Either<PaymentMethodValueFailure, StringStringItems>> processAndConfirmPaymentAsDirectCharge({
    required UserProfileModel userProfile,
    required ReservationItem reservationItem,
    required String amount,
    required String currency,
    required String? paymentMethod,
  });

  /// confirm Stripe payment intent
  Future<Either<PaymentMethodValueFailure, StringStringItems>> confirmExistingPaymentIntent({
    required String paymentIntentId
  });

  /// refund existing stripe payment
  Future<Either<PaymentMethodValueFailure, StringStringItems>> refundExistingStripePayment({
    required String refundAmount,
    required String paymentIntent
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