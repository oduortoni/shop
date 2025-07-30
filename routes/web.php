<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');
});

// Temporarily add to routes/web.php
Route::get('/debug', function() {
    return [
        'port' => $_SERVER['SERVER_PORT'] ?? 'not set',
        'env_port' => env('PORT', 'not set'),
        'db_connection' => config('database.default'),
        'db_path' => config('database.connections.sqlite.database'),
        'db_exists' => file_exists(config('database.connections.sqlite.database')),
        'app_key' => config('app.key') ? 'set' : 'NOT SET',
        'last_error' => get_last_error() // if you have error logging
    ];
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';
