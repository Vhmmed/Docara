sealed class CreateRecordState {
  const CreateRecordState();
}

class CreateRecordInitial extends CreateRecordState {
  const CreateRecordInitial();
}

class CreateRecordSubmitting extends CreateRecordState {
  const CreateRecordSubmitting();
}

class CreateRecordSuccess extends CreateRecordState {
  const CreateRecordSuccess();
}

class CreateRecordError extends CreateRecordState {
  final String message;
  const CreateRecordError(this.message);
}
