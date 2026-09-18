FROM oven/bun:1.3.13
WORKDIR /app
COPY . .
RUN bun install --frozen-lockfile
# Une image, deux consoles : `web` (Game Studio, 3001) ou `console`
# (Platform Console, 3002). Le port suit l'app via son vite.config.ts.
ARG APP=web
ARG PORT=3001
ENV APP=${APP}
EXPOSE ${PORT}
CMD bun run --cwd apps/$APP dev --host 0.0.0.0
