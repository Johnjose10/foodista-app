
FROM nginx:1.27-alpine

# Remove default Nginx files
RUN rm -rf /usr/share/nginx/html/*

# Copy Foodista website files
COPY . /usr/share/nginx/html/

# Expose Nginx port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
