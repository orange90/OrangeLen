# 标准无后缀 Dockerfile：多阶段构建示例
FROM node:22-alpine AS source
WORKDIR /app
COPY app/package.json app/server.js ./

FROM node:22-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=source --chown=node:node /app ./
USER node
EXPOSE 3000
CMD ["node", "server.js"]
