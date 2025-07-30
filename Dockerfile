# Base image with PHP and Apache
FROM php:8.3-apache

# Enable Apache rewrite module
RUN a2enmod rewrite

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev libonig-dev sqlite3 libsqlite3-dev \
    nodejs npm

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_sqlite zip

# Set working directory
WORKDIR /var/www/html

# Copy Laravel project
COPY . .

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Build frontend (React via Laravel Vite or Inertia)
RUN npm install && npm run build

# Ensure SQLite database file exists
RUN mkdir -p database \
 && touch database/database.sqlite \
 && chown -R www-data:www-data storage bootstrap/cache database \
 && chmod -R 775 storage bootstrap/cache database

# Laravel ENV expects SQLite path (for build-time)
ENV DB_CONNECTION=sqlite
ENV DB_DATABASE=/var/www/html/database/database.sqlite

# Copy custom Apache config (binds to $PORT for Render)
COPY ./render.apache.conf /etc/apache2/sites-available/000-default.conf

# Run migrations and seeders
RUN php artisan config:cache \
 && php artisan migrate --force \
 && php artisan db:seed --force

# Bind Apache to Render's dynamic port
RUN echo "Listen ${PORT:-8080}" > /etc/apache2/ports.conf

# Start Apache
CMD ["apache2-foreground"]
