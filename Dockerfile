# Base image with PHP and Apache
FROM php:8.3-apache

# Enable Apache rewrite module
RUN a2enmod rewrite

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    libzip-dev \
    libonig-dev \
    sqlite3 \
    libsqlite3-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_sqlite zip mbstring

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first for better layer caching
COPY composer.json composer.lock ./

# Install PHP dependencies (including dev dependencies for Faker)
RUN composer install --optimize-autoloader --no-scripts

# Copy package.json and package-lock.json for better layer caching
COPY package*.json ./

# Install Node dependencies
RUN npm ci --only=production

# Copy the rest of the application
COPY . .

# Build frontend assets
RUN npm run build

# Create necessary directories and set permissions
RUN mkdir -p database storage/logs storage/framework/{cache,sessions,views} bootstrap/cache \
    && touch database/database.sqlite \
    && chown -R www-data:www-data storage bootstrap/cache database \
    && chmod -R 775 storage bootstrap/cache database

# Set Laravel environment variables
ENV DB_CONNECTION=sqlite
ENV DB_DATABASE=/var/www/html/database/database.sqlite
ENV APP_ENV=production
ENV APP_DEBUG=false

# Copy custom Apache configuration if it exists
COPY ./render.apache.conf /etc/apache2/sites-available/000-default.conf

# Create entrypoint script
RUN echo '#!/bin/bash\n\
# Set default port if not provided\n\
PORT=${PORT:-10000}\n\
\n\
# Configure Apache to listen on the correct port\n\
echo "Listen $PORT" > /etc/apache2/ports.conf\n\
\n\
# Update VirtualHost to use the actual port number\n\
sed -i "s/\${PORT}/$PORT/g" /etc/apache2/sites-available/000-default.conf\n\
\n\
# Cache Laravel configuration\n\
php artisan config:cache\n\
php artisan route:cache\n\
php artisan view:cache\n\
\n\
# Start Apache\n\
exec apache2-foreground' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Expose port (for documentation purposes)
EXPOSE 10000

# Use the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]