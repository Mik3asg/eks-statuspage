# Backend Dockerfile
# What:  Packages the Node.js/Express API into a container image
# Why:   Gives us a portable, reproducible runtime — same image runs locally and on EKS
# Steps: install deps → copy source → expose port → start server

FROM node:20-alpine

WORKDIR /app

# Install dependencies first (separate layer — only re-runs when package.json changes)
COPY package*.json ./
RUN npm install --omit=dev

COPY src/ ./src/

EXPOSE 3000

CMD ["node", "src/index.js"]
