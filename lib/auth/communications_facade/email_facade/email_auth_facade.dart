part of check_in_facade;

@LazySingleton(as: EAuthFacade)
class EmailUpdaterFacade implements EAuthFacade {

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _fireStore;

  EmailUpdaterFacade(
      this._firebaseAuth,
      this._fireStore
    );


  @override
  Future<Either<AttendeeFormFailure, Unit>> createEmailNotification({required EmailNotificationItem email}) async {
    if (_firebaseAuth.currentUser == null || email.sendTo == null || (email.sendTo ?? []).isEmpty == true) {
      return right(unit);
    }

    final UniqueId mailRefId = UniqueId();
    final mailRef = _fireStore.collection('mail').doc(mailRefId.getOrCrash());

    ///send mail item
    final mailItem = {
      'to': email.sendTo,
      'attachments' : email.attachment,
      'template': {
        'name': email.template,
        'data': {
          'button_link': email.button_link,
          'reference_body_title' : email.reference_body_title
        }
      },
    };

    try {

      mailRef.set(mailItem);

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }



}