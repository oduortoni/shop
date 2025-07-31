<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');
});

Route::get('/debug', function() {
    return [
        'port' => $_SERVER['SERVER_PORT'] ?? 'not set',
        'env_port' => env('PORT', 'not set'),
        'db_connection' => config('database.default'),
        'db_path' => config('database.connections.sqlite.database'),
        'db_exists' => file_exists(config('database.connections.sqlite.database')),
        'app_key' => config('app.key') ? 'set' : 'NOT SET',
        'php_version' => phpversion(),
    ];
});

// Temporary debug route
Route::get('/debug-assets', function() {
    $buildPath = public_path('build');
    $files = [];
    
    if (is_dir($buildPath)) {
        $files = array_diff(scandir($buildPath), ['.', '..']);
    }
    
    return [
        'build_directory_exists' => is_dir($buildPath),
        'manifest_exists' => file_exists($buildPath . '/manifest.json'),
        'files_in_build' => $files,
        'vite_config' => config('vite'),
    ];
});

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';
