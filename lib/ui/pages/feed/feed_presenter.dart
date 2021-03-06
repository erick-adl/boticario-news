import '../../../main/pages/app_pages.dart';
import '../../helpers/user_session.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:meta/meta.dart' show required;

import '../../../domain/entities/post_entity.dart';
import '../../../domain/usecases/load_news.dart';
import '../../../domain/usecases/load_posts.dart';
import '../../../domain/usecases/remove_post.dart';
import '../../../domain/usecases/save_post.dart';
import '../../helpers/ui_error.dart';
import 'post_viewmodel.dart';

class FeedPresenter extends GetxController {
  final LoadNews loadNews;
  final LoadPosts loadPosts;
  final SavePost savePost;
  final RemovePost removePost;
  final LocalStorage localStorage;
  final UserSession userSession;

  final news = RxList<NewsViewModel>();
  final _isLoading = true.obs;
  final _errorMessage = ''.obs;
  final _errorMessageNewPost = Rx<UIError>();

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  UIError get errorMessageNewPost => _errorMessageNewPost.value;

  String _newPostMessage;

  FeedPresenter({
    @required this.loadNews,
    @required this.loadPosts,
    @required this.savePost,
    @required this.removePost,
    this.localStorage,
    this.userSession,
  });

  @override
  onInit() {
    super.onInit();
    load();
  }

  load() async {
    _errorMessage.value = '';
    try {
      final newsBoticario = await loadNews.load();
      final postsUsers = await loadPosts.load();

      newsBoticario.addAll(postsUsers);

      final sortedResult = newsBoticario
        ..sort(
          (a, b) => b.message.createdAt.compareTo(a.message.createdAt),
        );

      final postsViewModel =
          sortedResult.map((post) => toViewModel(post)).toList();

      news.assignAll(postsViewModel);
    } catch (error) {
      print(error);
      _errorMessage.update((_) {});

      _errorMessage.value = UIError.unexpected.description;
    } finally {
      _isLoading.value = false;
    }
  }

  save({int postId}) async {
    try {
      final post = await savePost.save(
        message: _newPostMessage,
        postId: postId,
      );

      if (postId == null) {
        news.insert(0, toViewModel(post));
      } else {
        var indexNews = news.indexWhere((post) => post.id == postId);
        news[indexNews] = toViewModel(post);
      }
    } catch (_) {
      _errorMessage.update((_) {});

      _errorMessage.value = UIError.unexpected.description;
    } finally {
      _isLoading.value = false;
    }
  }

  remove(int postId) async {
    try {
      await removePost.remove(postId: postId);

      news.removeWhere((post) => post.id == postId);
    } catch (error) {
      _errorMessage.update((_) {});

      _errorMessage.value = UIError.unexpected.description;
    } finally {
      _isLoading.value = false;
    }
  }

  clearMessagePost() {
    _errorMessageNewPost.value = null;
  }

  NewsViewModel toViewModel(PostEntity post) {
    // return NewsViewModel(
    //   id: post?.id,
    //   message: utf8.decode(post?.message?.content?.runes?.toList(),
    //       allowMalformed: true),
    //   date: DateFormat(DateFormat.YEAR_MONTH_DAY, 'pt_BR')
    //       .format(post?.message?.createdAt),
    //   user: utf8.decode(post?.user?.name?.runes?.toList()),
    //   userId: post?.user?.id,
    // );

    return NewsViewModel(
      id: post?.id,
      message: post?.message?.content,
      date: DateFormat(DateFormat.YEAR_MONTH_DAY, 'pt_BR')
          .format(post?.message?.createdAt),
      user: post?.user?.name,
      userId: post?.user?.id,
    );
  }

  handleNewPostMessage(String message) async {
    _newPostMessage = message;
    _validateNewPostMessage(message);
  }

  _validateNewPostMessage(String message) {
    if (message == null || message?.isEmpty == true) {
      _errorMessageNewPost.value = null;
      return;
    }

    _errorMessageNewPost.value =
        message.length > 280 ? UIError.invalidMessageNewPost : null;
  }

  void logoutUser() async {
    _isLoading.value = true;
    await localStorage.clear();
    userSession.clear();
    Get.offAllNamed(AppPages.welcome);
  }

  bool get isFormValid =>
      _errorMessageNewPost.value == null &&
      _newPostMessage != null &&
      _newPostMessage?.isNotEmpty == true;
}
