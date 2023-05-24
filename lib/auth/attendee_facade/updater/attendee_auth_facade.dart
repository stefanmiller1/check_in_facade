part of check_in_facade;

@LazySingleton(as: ATTAuthFacade)
class AttendeeFormFacade implements ATTAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseStorage _firebaseStorage;

  AttendeeFormFacade(
      this._fireStore,
      this._firebaseStorage);

  @override
  Future<Either<AttendeeFormFailure, Unit>> createNewAttendee({required AttendeeItem attendeeItem}) async {

    late AttendeeItem attendee;
    attendee = attendeeItem;

    try {

      ///upload attendee profile item
      if (attendeeItem.attendeeType == AttendeeType.vendor) {
        if (attendeeItem.eventMerchantVendorProfile != null && attendeeItem.eventMerchantVendorProfile!.vendorLogo != null) {
          final Uint8List imageData = attendeeItem.eventMerchantVendorProfile!.vendorLogo!;
          /// store the file
          final urlId = UniqueId();
          final reference = _firebaseStorage.ref('activity_directory').child(attendeeItem.reservationId.getOrCrash()).child('vendors');
          await reference.child(urlId.getOrCrash()).putData(imageData);

          /// retrieve link to file stored in firebase storage
          final uri = await reference.child(urlId.getOrCrash()).getDownloadURL();

          final EventMerchantVendorProfile eventVendorMerchant = EventMerchantVendorProfile(
            brandName: attendeeItem.eventMerchantVendorProfile!.brandName,
            backgroundInfo: attendeeItem.eventMerchantVendorProfile!.backgroundInfo,
            uriImage: uri
          );

          attendee = attendee.copyWith(
              eventMerchantVendorProfile: eventVendorMerchant
          );
        }
      }


      final attendeeFormDto = AttendeeItemDto.fromDomain(attendee).toJson();

      final activityDoc = await _fireStore.activityDocument(attendee.reservationId.getOrCrash());
      final attendeeDoc = activityDoc.collection('attendees').doc(attendee.attendeeId.getOrCrash());
      attendeeDoc.set(attendeeFormDto);


      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const AttendeeFormFailure.attendeePermissionDenied());
      } else {
        return left(AttendeeFormFailure.attendeeServerError(failed: e.code));
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return left(const AttendeeFormFailure.attendeePermissionDenied());
      }
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }

  }

}