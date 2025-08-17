<div align="center">

## Redis Cluster with Docker Compose

<p><em>Redis를 Docker Compose에서 클러스터 모드로 구성하여, <br>
고가용성과 효율적인 데이터 분산을 구현했습니다.</em></p>

<img src="https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white" />
<img src="https://img.shields.io/badge/Docker%20Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" />

</div>

### 🚀 실행 방법

**1. Docker Compose 설치 확인**

```bash
docker compose version
```

**2. Redis 클러스터 배포**

```bash
# deploy.sh 스크립트 실행
./deploy.sh
```
> deploy.sh는 Redis 클러스터를 Docker Compose로 배포하는 스크립트입니다.

**3. 클러스터 상태 확인**

```bash
# 클러스터 정보 조회
docker exec redis-master-1 redis-cli cluster info

# 노드 목록 확인
docker exec redis-master-1 redis-cli cluster nodes

# 클러스터 모드로 접속
docker exec -it redis-master-1 redis-cli -c
```

<br>

### ✨ 접속 정보

**포트 매핑**

| 노드 | Redis 포트 | 클러스터 버스 포트 |
|------|------------|-------------------|
| redis-master-1 | 7001 | 17001 |
| redis-master-2 | 7002 | 17002 |
| redis-master-3 | 7003 | 17003 |
| redis-replica-1 | 7004 | 17004 |
| redis-replica-2 | 7005 | 17005 |
| redis-replica-3 | 7006 | 17006 |

**클러스터 접속 예시**

```bash
# 클러스터 모드로 접속 (마스터 노드 중 하나 선택)
redis-cli -c -p 7001
redis-cli -c -p 7002
redis-cli -c -p 7003
```

<br>

### 🗑️ 클러스터 제거

```bash
docker-compose down
```
