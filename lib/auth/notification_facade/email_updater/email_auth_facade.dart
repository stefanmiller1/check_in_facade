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
  Future<Either<AttendeeFormFailure, Unit>> createEmailNotification({required List<String>? sendTo, required String? template, required String? button_link, required String? reference_body_title, required Map<String, dynamic>? attachment}) async {
    if (_firebaseAuth.currentUser == null || sendTo == null || sendTo.isEmpty == true) {
      return right(unit);
    }

    final UniqueId mailRefId = UniqueId();
    final mailRef = _fireStore.collection('mail').doc(mailRefId.getOrCrash());

    ///send mail item
    final mailItem = {
      'to': sendTo,
      'attachments' : attachment,
      'template': {
        'name': template,
        'data': {
          'button_link': button_link,
          'reference_body_title' : reference_body_title
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