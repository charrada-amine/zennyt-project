FROM oven/bun:1.3.13
WORKDIR /app
COPY . .
RUN bun install --frozen-lockfile
EXPOSE 3001
CMD ["bun", "run", "--cwd", "apps/web", "dev", "--host", "0.0.0.0"]
