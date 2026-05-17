# ── Stage 1: just serve the static site ──
FROM nginx:alpine

# Copy all website files into nginx
COPY index.html style.css app.js /usr/share/nginx/html/

# nginx listens on port 80 by default
EXPOSE 80

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
