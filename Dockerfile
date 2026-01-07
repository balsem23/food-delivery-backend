# Laravel on Render (Docker) - Apache + PHP 8.2
FROM php:8.2-apache

# System dependencies + PHP extensions Laravel commonly needs
RUN apt-get update && apt-get install -y \
    git unzip zip curl \
    libzip-dev libpng-dev libonig-dev libxml2-dev \
  && docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl \
  && a2enmod rewrite \
  && rm -rf /var/lib/apt/lists/*

# Point Apache to Laravel's public/ folder
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Workdir
WORKDIR /var/www/html

# Copy app code
COPY . .

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Clean install (fixes corrupted/partial vendor issues like Carbon trait errors)
RUN composer clear-cache \
 && rm -rf vendor \
 && composer install --no-interaction --prefer-dist --optimize-autoloader

# Permissions for Laravel cache/logs
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
