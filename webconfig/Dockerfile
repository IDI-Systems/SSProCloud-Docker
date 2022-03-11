FROM php:8.1-apache

# Pro Cloud WebConfig requires PHP extension:
#   core, curl, date, gettext, hash, json, libxml, mbstring, pcre, session, standard, tokenizer
# All but gettext are pre-installed
RUN docker-php-ext-install -j$(nproc) gettext

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
