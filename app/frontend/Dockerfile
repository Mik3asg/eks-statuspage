# Frontend Dockerfile — two-stage build
# What:  Stage 1 compiles React → static files. Stage 2 serves them via nginx.
# Why:   The build stage (Node + Vite) is heavy; the final image only needs nginx + HTML/JS/CSS
# Steps: install → build → copy dist into nginx image → serve

# Stage 1 — build
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2 — serve (tiny nginx image, no Node.js at all)
FROM nginx:alpine

# Replace default nginx config with ours (API proxy + WS upgrade + SPA routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled assets from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
