package com.example.app;

import android.app.Activity;
import android.os.Bundle


class HelloAndroid : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}