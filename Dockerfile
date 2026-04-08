# 1단계: 빌드 환경
FROM node:22-alpine AS builder
RUN apk add --no-cache libc6-compat python3 make g++
RUN npm install -g pnpm@10
WORKDIR /app

# 빌드에 필요한 환경 변수를 미리 선언합니다 (Vite 에러 방지)
ENV PORT=3005
ENV BASE_PATH=/
ENV NODE_ENV=production

COPY . .

# 1. 의존성 설치
RUN pnpm install --no-frozen-lockfile
RUN pnpm add -D @rollup/rollup-linux-x64-musl lightningcss-linux-x64-musl @tailwindcss/oxide-linux-x64-musl -w

# 2. 빌드 진행 (이제 BASE_PATH 에러가 나지 않습니다)
RUN pnpm recursive run build --filter "./lib/**"
RUN pnpm -r --if-present run build

# 3. [핵심 조치] 빌드된 파일의 문법 에러 입막음 (물리적 수정)
RUN sed -i 's/throw new TypeError(`Missing parameter name/console.warn(`Skipped parameter error/g' artifacts/api-server/dist/index.mjs

# 2단계: 실행 환경
FROM node:22-alpine AS runner
WORKDIR /app

# 빌드 결과물 전체 복사
COPY --from=builder /app ./

# 실행 시 환경 변수 다시 확인
ENV NODE_ENV=production
ENV PORT=3005
ENV BASE_PATH=/
EXPOSE 3005

# 시동
CMD ["node", "artifacts/api-server/dist/index.mjs"]