package com.example.jazzcash_payment_app;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.jazzcash_payment_app/performPayment";
    private static final int PAYMENT_ACTIVITY_RESULT_CODE = 101;
    private MethodChannel.Result _result;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Initialize the Platform Channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    _result = result;
                    if (call.method.equals("performPayment")) {
                        String postData = call.argument("postData");
                        Intent intent = new Intent(MainActivity.this, PaymentActivity.class);
                        intent.putExtra("postData", postData);
                        startActivityForResult(intent, PAYMENT_ACTIVITY_RESULT_CODE);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == PAYMENT_ACTIVITY_RESULT_CODE) {
            // Parse response data back as a map
            String response = "";
            if (data != null) {
                response = data.getStringExtra("response");
            }

            if (_result != null) {
                _result.success(response);
                _result = null; // Reset the result after processing
            }
        }
    }
}