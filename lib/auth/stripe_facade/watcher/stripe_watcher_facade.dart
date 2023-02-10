part of check_in_facade;

abstract class SStripeWatcherFacade {

  /// watch Stripe customer payment methods
  Stream<Either<PaymentMethodValueFailure, List<CardItem>>> watchCustomerPaymentMethod({required String customerId});

  /// watch Stripe customer payment history
  Stream<Either<PaymentMethodValueFailure, List<PaymentIntent>>> watchCustomerPaymentIntents({required String customerId});

  /// watch Stripe account payout history
  Stream<Either<PaymentMethodValueFailure, List<PayoutModel>>> watchPayoutHistory();
}