## Redis 클러스터 with Docker Swarm

Docker Swarm을 사용한 Redis 클러스터 구성입니다.

### 아키텍처

- **마스터 노드**: 3개 (redis-master-1, redis-master-2, redis-master-3)
- **레플리카 노드**: 3개 (redis-replica-1, redis-replica-2, redis-replica-3)
- **데이터 분산**: 16384개 해시 슬롯을 3개 마스터에 자동 분산
- **고가용성**: 각 마스터마다 1개의 레플리카 보유

<br>

### 실행 방법

#### 1: Docker Swarm 초기화

```bash
# Swarm 모드 활성화
docker swarm init

# Swarm 상태 확인
docker node ls
```

#### 2: Redis 클러스터 배포

```bash
# 스택 배포
docker stack deploy -c redis.yml redis-cluster

# 서비스 상태 확인
docker service ls
```

#### 3: 클러스터 초기화

```bash
# 클러스터 생성
docker exec $(docker ps -q -f name=redis-master-1) redis-cli --cluster create \
  redis-master-1:6379 redis-master-2:6379 redis-master-3:6379 \
  redis-replica-1:6379 redis-replica-2:6379 redis-replica-3:6379 \
  --cluster-replicas 1 --cluster-yes
```

#### 4: 클러스터 상태 확인

```bash
# 클러스터 정보 확인
docker exec $(docker ps -q -f name=redis-master-1) redis-cli cluster info

# 노드 정보 확인
docker exec $(docker ps -q -f name=redis-master-1) redis-cli cluster nodes

# 클러스터 모드로 접속해서 테스트
docker exec -it $(docker ps -q -f name=redis-master-1) redis-cli -c
```

<br>

### 접속 정보

#### 외부 접속 포트

| 노드 | Redis 포트 | 클러스터 버스 포트 |
|------|------------|-------------------|
| redis-master-1 | 7001 | 17001 |
| redis-master-2 | 7002 | 17002 |
| redis-master-3 | 7003 | 17003 |
| redis-replica-1 | 7004 | 17004 |
| redis-replica-2 | 7005 | 17005 |
| redis-replica-3 | 7006 | 17006 |

#### 클라이언트 접속 예시

```bash
# 로컬에서 클러스터 모드로 접속
redis-cli -c -p 7001

# 다른 포트로도 접속 가능
redis-cli -c -p 7002
redis-cli -c -p 7003
```

```bash
# 스택 제거
docker stack rm redis-cluster
```
