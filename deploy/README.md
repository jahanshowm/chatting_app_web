# Admin Web 배포 (Flutter build + rsync만)

Apache / nginx / SSL / DNS / systemd는 **서버 담당** 영역입니다.

## 스크립트 목록

| 스크립트 | 대상 | 하는 일 |
|----------|------|---------|
| `deploy-admin.sh` | config 기준 | Web 빌드 + rsync |
| `deploy-admin-dev.sh` | admin-dev.adminchat.kr | ↑ + admin-dev config |
| `deploy-adminchat.sh` | adminchat.kr | ↑ + adminchat config |
| `deploy-all.sh` | adminchat.kr | Backend + Admin Web |
| `deploy-all-randomchat.sh` | randomchat.kr | Backend + Admin Web |

## 사용법

### admin-dev (chat-test)

```bash
./deploy/deploy-admin-dev.sh
SKIP_WEB_BUILD=1 ./deploy/deploy-admin-dev.sh
```

### adminchat.kr (운영)

```bash
./deploy/deploy-all.sh
./deploy/deploy-admin.sh
```

### randomchat.kr (운영)

```bash
./deploy/deploy-all-randomchat.sh
DEPLOY_CONFIG=deploy/deploy.config.randomchat ./deploy/deploy-admin.sh
```

## QA API (백엔드)

```bash
# randomchat_back/deploy/deploy-chat-test.sh
```

## 설정 파일

| 파일 | 용도 |
|------|------|
| `deploy.config` | adminchat.kr 기본 |
| `deploy.config.adminchat` | adminchat.kr |
| `deploy.config.randomchat` | randomchat.kr |
| `deploy.config.admin-dev` | admin-dev.adminchat.kr |
| `.env.build.adminchat` | adminchat.kr 빌드 API |
| `.env.build.randomchat` | randomchat.kr 빌드 API |
| `.env.build.admin-dev` | admin-dev 빌드 API |

## 배포 후 확인

```bash
curl -sI https://<도메인>/ | head -1
curl -s https://<도메인>/api/health
```

`/api/health` 404 → Apache 프록시 미설정, **서버 담당에게 문의**.
