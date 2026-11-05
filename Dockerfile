FROM oven/bun:1.3.14-slim AS build

WORKDIR /app

ENV NUXT_TELEMETRY_DISABLED=1 \
    NODE_OPTIONS=--max-old-space-size=4096

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .

# These values are baked into app.head and the sitemap at build time. The API
# and OSS URLs are deliberately NOT set here: setting them would make Nuxt bake
# routeRules proxies for /api/** and /oss/**, while the project already proxies
# those paths at runtime from server/routes/*.ts. Runtime env wins there.
ARG SITE_NAME=""
ARG SITE_DESCRIPTION=""
ARG SITE_KEYWORDS=""
ARG SITE_DOMAIN="https://shermant.com"
ENV NUXT_PUBLIC_SITE_NAME=$SITE_NAME \
    NUXT_PUBLIC_SITE_DESCRIPTION=$SITE_DESCRIPTION \
    NUXT_PUBLIC_SITE_KEYWORDS=$SITE_KEYWORDS \
    NUXT_PUBLIC_SITE_DOMAIN=$SITE_DOMAIN

RUN bun run build

FROM node:24.16-slim AS runtime

WORKDIR /app

RUN groupadd --system nuxt \
 && useradd --system --gid nuxt --home-dir /app --shell /usr/sbin/nologin nuxt

COPY --from=build --chown=nuxt:nuxt /app/.output ./.output
COPY --from=build --chown=nuxt:nuxt /app/scripts ./scripts

ENV NODE_ENV=production \
    NITRO_HOST=0.0.0.0 \
    PORT=3000

USER nuxt

EXPOSE 3000

ENTRYPOINT ["sh", "scripts/start-nitro.sh"]
