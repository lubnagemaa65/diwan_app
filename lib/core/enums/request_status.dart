enum RequestStatus {
  idle,
  loading,
  success,
  failure,
  submitted,
  approved,
  rejected,
  inReview,
}

extension RequestStatusExtension on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.submitted:
        return 'تم الإرسال';
      case RequestStatus.inReview:
        return 'قيد المراجعة';
      case RequestStatus.approved:
        return 'مقبول';
      case RequestStatus.rejected:
        return 'مرفوض';
      case RequestStatus.loading:
        return 'جاري التحميل';
      case RequestStatus.success:
        return 'ناجح';
      case RequestStatus.failure:
        return 'فشل';
      case RequestStatus.idle:
        return 'خامل';
    }
  }
}
