String parseApiErrorMessage(dynamic body, {String fallback = '요청 처리 중 오류가 발생했습니다.'}) {
  if (body is Map) {
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
  }
  return fallback;
}
