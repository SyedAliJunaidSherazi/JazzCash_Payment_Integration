import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
// For accessing the Platform Channel functionality
import 'package:flutter/services.dart';
// For use in the hashing function
import 'package:crypto/crypto.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
// Reference to the PlatformChannel
  // com.<YOUR_APPLICATION_NAME>/<YOUR_FUNCTION_NAME>
  static const platform = const MethodChannel('com.example.jazzcash_payment_app/performPayment');

// Integrity Salt provided by the payment gateway
  // The salt is used in conjunction with the hashing function
  static const integritySalt = '##########';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ElevatedButton(
              onPressed: payWithJazzCash,
              child: Text('Pay with Jazz Cash'),
            ),
          ),
        ),
      ),
    );
  }

  String hashingFunc(Map<String, String> data) {
    // Sorting data based on keys
    var sortedKeys = data.keys.toList(growable: false)..sort();
    var sortedMap = {for (var k in sortedKeys) k: '${data[k]!}&'};

    var values = sortedMap.values.join();
    values = values.substring(0, values.length - 1);
    var toBeHashed = '$integritySalt&$values';

    var key = utf8.encode(integritySalt);
    var bytes = utf8.encode(toBeHashed);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    var hash = digest.toString();

    return {...data, "pp_SecureHash": hash}
        .entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  Future<void> payWithJazzCash() async {
    // Define transaction start and expiry times
    final startTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final expiryTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now().add(Duration(minutes: 5)));
    final referenceNumber = 'T' + startTime;

    // Prepare the data to be sent in the payment request
    var requestData = {
      "pp_Amount": "<AMOUNT>",
      "pp_BillReference": "billRef",
      "pp_Description": "Transaction Description",
      "pp_Language": "EN",
      "pp_MerchantID": "######",
      "pp_Password": "########",
      "pp_ReturnURL": "http://(localhost or domain)/your_return_backend_url.(eg: php)",
      "pp_TxnCurrency": "PKR",
      "pp_TxnDateTime": startTime,
      "pp_TxnExpiryDateTime": expiryTime,
      "pp_TxnRefNo": referenceNumber,
      "pp_TxnType": "",
      "pp_Version": "1.1",
      "pp_BankID": "TBANK",
      "pp_ProductID": "RETL",
      "ppmpf_1": "1",
      "ppmpf_2": "2",
      "ppmpf_3": "3",
      "ppmpf_4": "4",
      "ppmpf_5": "5",
    };

    String postData = hashingFunc(requestData);
    String responseString = '';

    try {
      final result = await platform.invokeMethod(
        'performPayment',
        {"postData": postData},
      );
      responseString = result.toString();
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }

    // Parse and handle the response
    List<String> responseList = responseString.split('&');
    Map<String, String> response = {};
    for (var item in responseList) {
      if (item.isNotEmpty) {
        var keyValue = item.split('=');
        response[keyValue[0]] = keyValue[1];
      }
    }

    // Handle the response as needed
    print(response);
  }

}