<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Artisan;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (app()->environment('production')) {
            $migrationLock = storage_path('app/migration.lock');

            if (!file_exists($migrationLock)) {
                Artisan::call('migrate', ['--force' => true]);

                // Only run seeder if Faker is available (dev dependencies installed)
                if (class_exists(\Faker\Factory::class)) {
                    Artisan::call('db:seed', ['--force' => true]);
                }

                file_put_contents($migrationLock, 'migrated');
            }
        }
    }
}
