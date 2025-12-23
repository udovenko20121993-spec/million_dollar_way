import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:async';

class IbkrApiService {
  static const String _baseUrl =
      "https://www.interactivebrokers.com/Universal/servlet/FlexStatementService";

  Future<String> downloadReport(String token, String queryId) async {
    try {
      // 1. Запит на генерацію
      final requestUrl = Uri.parse(
        "$_baseUrl.SendRequest?t=$token&q=$queryId&v=3",
      );
      print("IBKR: Відправляю запит на $requestUrl");

      final initialResponse = await http.get(requestUrl);

      if (initialResponse.statusCode != 200) {
        throw "Помилка сервера IBKR: ${initialResponse.statusCode}";
      }

      final document = XmlDocument.parse(initialResponse.body);
      final status = document.findAllElements('Status').firstOrNull?.innerText;

      if (status != 'Success') {
        final errorCode = document
            .findAllElements('ErrorCode')
            .firstOrNull
            ?.innerText;
        final errorMsg = document
            .findAllElements('ErrorMessage')
            .firstOrNull
            ?.innerText;
        throw "IBKR Error: $errorMsg (Code: $errorCode)";
      }

      final referenceCode = document
          .findAllElements('ReferenceCode')
          .firstOrNull
          ?.innerText;
      String baseUrlNode =
          document.findAllElements('Url').firstOrNull?.innerText ?? "";

      // Підміна домену
      if (baseUrlNode.contains("gdcdyn.interactivebrokers.com")) {
        print("IBKR: Замінюю неробочий домен gdcdyn на www...");
        baseUrlNode = baseUrlNode.replaceAll(
          "gdcdyn.interactivebrokers.com",
          "www.interactivebrokers.com",
        );
      }

      if (referenceCode == null || baseUrlNode.isEmpty)
        throw "Не вдалося отримати ReferenceCode.";

      print("IBKR: Звіт генерується (Ref: $referenceCode). Чекаємо...");

      // 2. ОЧІКУВАННЯ (ЗБІЛЬШЕНО ЧАС)
      // Було 10 спроб, ставимо 60 (це 2 хвилини максимуму)
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 2));

        final downloadUrl = Uri.parse(
          "$baseUrlNode?q=$referenceCode&t=$token&v=3",
        );
        final reportResponse = await http.get(downloadUrl);

        if (reportResponse.body.contains('Statement is being generated') ||
            reportResponse.body.contains('Fail')) {
          // Виводимо крапку, щоб не засмічувати лог
          print("IBKR: Ще генерується... (Спроба ${i + 1}/60)");
          continue;
        }

        if (reportResponse.statusCode == 200) {
          print(
            "IBKR: ✅ Звіт завантажено! Розмір: ${reportResponse.body.length} байт",
          );
          return reportResponse.body;
        }
      }

      throw "Тайм-аут: Звіт генерувався довше 2 хвилин.";
    } catch (e) {
      print("IBKR API Error: $e");
      rethrow;
    }
  }
}
