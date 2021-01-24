import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart' show required;

class NewsViewModel extends Equatable {
  final String message;
  final String date;
  final String user;

  NewsViewModel(
      {@required this.message, @required this.date, @required this.user});

  @override
  List get props => [message, date, user];

  @override
  bool get stringify => true;
}