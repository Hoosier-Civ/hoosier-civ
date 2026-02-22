import 'package:flutter_bloc/flutter_bloc.dart';

class UserState {
  final bool isAuthenticated;

  const UserState({this.isAuthenticated = false});
}

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(const UserState());
}
