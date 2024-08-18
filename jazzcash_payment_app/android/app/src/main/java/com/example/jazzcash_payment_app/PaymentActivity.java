package com.example.jazzcash_payment_app;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.graphics.Bitmap;

public class PaymentActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.jazzcash_payment_app/performPayment";
    private static private static final String PAYMENT_URL = "https://example.com/payment";
    private static final String PAYMENT_RETURN_URL = "https://example.com/callback";


    private WebView mWebView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_payment);
        mWebView = findViewById(R.id.webview);

        // Get postData from the Intent
        Intent intentData = getIntent();
        String postData = intentData.getStringExtra("postData");

        // Configure WebView settings
        WebSettings webSettings = mWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);

        mWebView.setWebViewClient(new MyWebViewClient());

        // Add JavaScript interface to WebView
        mWebView.addJavascriptInterface(new FormDataInterface(), "FORMOUT");

        // Post data to the payment URL
        mWebView.postUrl(PAYMENT_URL, postData.getBytes());
    }

    private class MyWebViewClient extends WebViewClient {
        private final String jsCode = "" +
                "function parseForm(form) {" +
                "   var values = '';" +
                "   for (var i = 0; i < form.elements.length; i++) {" +
                "       values += form.elements[i].name + '=' + form.elements[i].value + '&';" +
                "   }" +
                "   var url = form.action;" +
                "   console.log('parse form fired');" +
                "   window.FORMOUT.processFormData(url, values);" +
                "}" +
                "for (var i = 0; i < document.forms.length; i++) {" +
                "   parseForm(document.forms[i]);" +
                "};";

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            if (url.equals(PAYMENT_RETURN_URL)) {
                System.out.println("Equal On Page Started: " + url);
                view.stopLoading();
                return;
            }
            super.onPageStarted(view, url, favicon);
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            if (!url.equals(PAYMENT_RETURN_URL)) {
                view.loadUrl("javascript:(function() { " + jsCode + " })()");
            }
            super.onPageFinished(view, url);
        }
    }

    private class FormDataInterface {
        @JavascriptInterface
        public void processFormData(String url, String formData) {
            Intent i = new Intent(PaymentActivity.this, MainActivity.class);

            if (url.equals(PAYMENT_RETURN_URL)) {
                i.putExtra("response", formData);
                setResult(RESULT_OK, i);
                finish();
            }
        }
    }
}