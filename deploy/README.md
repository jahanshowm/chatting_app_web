# Admin Web 배포 (Flutter build + rsync만)

Apache / nginx / SSL / DNS / systemd는 **서버 담당** 영역입니다.  
**한 번에 API+Web을 묶는 스크립트는 없습니다.** QA·운영을 경로별로 따로 배포합니다.

## 스크립트

| 스크립트 | 환경 | 경로 |
|----------|------|------|
| `deploy-adminchat.sh` | 운영 | `/home/users/adminchat/www` → https://adminchat.kr |
| `deploy-admin-dev.sh` | QA | `/home/users/admin-dev/www` → https://admin-dev.adminchat.kr |
| `deploy-admin.sh` | — | 공통 엔진 (직접 실행 금지) |

## 사용법

### QA
```bash
./deploy/deploy-admin-dev.sh
```

### 운영
```bash
./deploy/deploy-adminchat.sh
```

API는 백엔드 레포에서 따로:

```bash
# QA API (cwd: randomchat_back/)
./deploy/deploy-chat-test.sh

# 운영 Admin API (cwd: randomchat_back/)
./deploy/deploy-adminchat-api.sh
```

## 설정 파일

| 파일 | 용도 |
|------|------|
| `deploy.config` | 운영 adminchat.kr |
| `deploy.config.admin-dev` | QA admin-dev |
| `.env.build.adminchat` | 운영 빌드 API |
| `.env.build.admin-dev` | QA 빌드 API |

## 배포 후 확인

```bash
curl -sI https://adminchat.kr/ | head -1
curl -s https://adminchat.kr/api/health
curl -sI https://admin-dev.adminchat.kr/ | head -1
```
