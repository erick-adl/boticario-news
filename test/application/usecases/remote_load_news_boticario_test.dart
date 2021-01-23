import 'dart:convert';

import 'package:boticario_news/application/http/http_client.dart';
import 'package:boticario_news/application/http/http_error.dart';
import 'package:boticario_news/application/models/news_model.dart';
import 'package:boticario_news/domain/entities/news_entity.dart';
import 'package:boticario_news/domain/errors/domain_error.dart';
import 'package:faker/faker.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';

import '../../mocks/mocks.dart';

class HttpClientMock extends Mock implements HttpClient {}

class RemoteLoadNewsBoticario {
  final HttpClient httpClient;
  final String url;

  RemoteLoadNewsBoticario({@required this.httpClient, @required this.url});

  Future<List<NewsEntity>> load() async {
    try {
      final response = await httpClient.request(url: url, method: 'get');
      return (response['news'] as List)
          .map((json) => NewsModel.fromJson(json))
          .toList();
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}

void main() {
  RemoteLoadNewsBoticario sut;
  HttpClientMock httpClient;
  String url;

  setUp(() {
    httpClient = HttpClientMock();
    url = faker.internet.httpUrl();

    sut = RemoteLoadNewsBoticario(
      httpClient: httpClient,
      url: url,
    );
  });

  test('Should call HttpClient with correct values', () async {
    when(
      httpClient.request(
        url: anyNamed('url'),
        method: anyNamed('method'),
      ),
    ).thenAnswer((_) async => jsonDecode(apiResponseNewsBoticario));

    await sut.load();

    verify(
      httpClient.request(
        url: url,
        method: 'get',
      ),
    );
  });

  test('Should return news on 200', () async {
    when(
      httpClient.request(
        url: anyNamed('url'),
        method: anyNamed('method'),
      ),
    ).thenAnswer((_) async => jsonDecode(apiResponseNewsBoticario));

    final news = await sut.load();

    expect(news, isA<List<NewsEntity>>());
    expect(news[0].user.name, equals('O Boticário'));
  });

  test('Should throw UnexpectedError if HttpClient not returns 200', () {
    when(
      httpClient.request(
        url: anyNamed('url'),
        method: anyNamed('method'),
      ),
    ).thenThrow(HttpError.serverError);

    final future = sut.load();

    expect(future, throwsA(DomainError.unexpected));
  });
}