# Base image with PHP and Apache
FROM php:8.3-apache

# Enable Apache rewrite module and set ServerName
RUN a2enmod rewrite \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

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

# Install PHP dependencies (including dev dependencies for build)
RUN composer install --no-scripts --no-interaction

# Copy package.json and package-lock.json for better layer caching
COPY package*.json ./

# Install Node dependencies (including dev dependencies for build)
RUN npm ci

# Copy the rest of the application
COPY . .

# Copy environment file
RUN cp .env.example .env

# Set Node.js environment for build
ENV NODE_ENV=production
ENV VITE_APP_NAME="Laravel"

# Build frontend assets (client-side only for production)
RUN npm run build

# Verify build was successful and set permissions
RUN if [ -f public/build/manifest.json ]; then \
        echo "Manifest found at public/build/manifest.json"; \
        chmod 644 public/build/manifest.json; \
    elif [ -f public/build/.vite/manifest.json ]; then \
        echo "Manifest found at public/build/.vite/manifest.json, moving to expected location"; \
        mv public/build/.vite/manifest.json public/build/manifest.json; \
        chmod 644 public/build/manifest.json; \
    else \
        echo "ERROR: Vite manifest not found!"; \
        echo "Contents of public/build directory:"; \
        find public/build -type f | head -20; \
        exit 1; \
    fi

# Remove dev dependencies to reduce image size
RUN composer install --no-dev --no-scripts --no-interaction && \
    npm prune --production

# Create necessary directories and set permissions
RUN mkdir -p database storage/app storage/logs storage/framework/{cache,sessions,views} bootstrap/cache \
    && touch database/database.sqlite \
    && chown -R www-data:www-data storage bootstrap/cache database public/build \
    && chmod -R 775 storage bootstrap/cache database \
    && chmod -R 755 public/build

# Set Laravel environment variables
ENV DB_CONNECTION=sqlite
ENV DB_DATABASE=/var/www/html/database/database.sqlite
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV APP_URL=https://shop-s7f7.onrender.com
ENV ASSET_URL=https://shop-s7f7.onrender.com
ENV INERTIA_SSR_ENABLED=false

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
# Debug: Check if manifest exists\n\
echo "Checking Vite manifest..."\n\
ls -la public/build/\n\
\n\
# Generate app key if not set\n\
if [ -z "$APP_KEY" ]; then\n\
    echo "Generating application key..."\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Cache Laravel configuration\n\
php artisan config:cache\n\
\n\
# Clear any existing route cache and test routes before caching\n\
php artisan route:clear\n\
echo "Testing route registration..."\n\
php artisan route:list | head -10 || echo "Route listing failed"\n\
\n\
# Cache routes only if they load successfully\n\
php artisan route:cache || echo "Route caching failed, continuing without cache"\n\
php artisan view:cache\n\
\n\
# Start Apache\n\
exec apache2-foreground' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Expose port (for documentation purposes)
EXPOSE 10000

# Use the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]