import 'package:flutter_bloc/flutter_bloc.dart';

class UnreadCountCubit extends Cubit<int> {
  UnreadCountCubit() : super(0);

  void setCount(int count) => emit(count);
}
