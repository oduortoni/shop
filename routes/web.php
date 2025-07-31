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
        'vite_config' => 'No vite config file (this is normal)',
        'app_env' => app()->environment(),
        'routes_cached' => app()->routesAreCached(),
    ];
});

// Debug route for routes
Route::get('/debug-routes', function() {
    $routes = collect(\Illuminate\Support\Facades\Route::getRoutes())->map(function($route) {
        return [
            'uri' => $route->uri(),
            'methods' => $route->methods(),
            'name' => $route->getName(),
        ];
    })->take(20);

    return [
        'total_routes' => count(\Illuminate\Support\Facades\Route::getRoutes()),
        'sample_routes' => $routes,
        'has_login_route' => \Illuminate\Support\Facades\Route::has('login'),
        'has_register_route' => \Illuminate\Support\Facades\Route::has('register'),
    ];
});

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

// Test route to check if routing works
Route::get('/test-login', function () {
    return response()->json([
        'message' => 'Test route works',
        'login_route_exists' => \Illuminate\Support\Facades\Route::has('login'),
        'register_route_exists' => \Illuminate\Support\Facades\Route::has('register'),
        'login_url' => \Illuminate\Support\Facades\Route::has('login') ? route('login') : 'Route not found',
        'register_url' => \Illuminate\Support\Facades\Route::has('register') ? route('register') : 'Route not found',
        'auth_routes' => collect(\Illuminate\Support\Facades\Route::getRoutes())
            ->filter(function($route) {
                return str_contains($route->uri(), 'login') || str_contains($route->uri(), 'register');
            })
            ->map(function($route) {
                return [
                    'uri' => $route->uri(),
                    'methods' => $route->methods(),
                    'name' => $route->getName(),
                ];
            })
            ->values()
    ]);
});

// Simple test route that should work with Inertia
Route::get('/test-inertia', function () {
    return Inertia::render('welcome');
})->name('test.inertia');

// Test Ziggy route generation
Route::get('/test-ziggy', function () {
    $ziggy = new \Tighten\Ziggy\Ziggy();
    return response()->json([
        'ziggy_routes' => $ziggy->toArray(),
        'has_login_in_ziggy' => isset($ziggy->toArray()['routes']['login']),
        'has_register_in_ziggy' => isset($ziggy->toArray()['routes']['register']),
        'login_route_details' => $ziggy->toArray()['routes']['login'] ?? 'Not found',
        'register_route_details' => $ziggy->toArray()['routes']['register'] ?? 'Not found',
    ]);
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';
