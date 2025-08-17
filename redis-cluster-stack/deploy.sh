#!/bin/bash

echo "🚀 Redis 클러스터 배포"

# Swarm 모드 확인
if ! docker info 2>/dev/null | grep -i "swarm: active" > /dev/null; then
    echo "Docker Swarm 모드가 비활성화되어 있습니다."
    echo "다음 명령어로 활성화하세요: docker swarm init"
    exit 1
fi

# 기존 스택 제거
echo "기존 스택 정리 중..."
docker stack rm redis-cluster 2>/dev/null || true
sleep 10

# 새 스택 배포
echo "Redis 클러스터 배포 중..."
docker stack deploy -c redis.yaml redis-cluster

# 서비스 상태 확인 및 대기
echo "서비스 시작 대기 중..."
sleep 60

# 모든 컨테이너가 실행 중인지 확인
echo "컨테이너 상태 확인 중..."
for i in {1..30}; do
    running_count=$(docker ps --filter "name=redis-" --format "table {{.Names}}" | grep -E "(master|replica)" | wc -l)
    if [ "$running_count" -eq 6 ]; then
        echo "모든 컨테이너가 실행되었습니다."
        break
    fi
    echo "대기 중... ($running_count/6 컨테이너 실행됨)"
    sleep 10
done

# 기존 데이터 정리
echo "기존 데이터 정리 중..."
for i in 1 2 3; do 
    # 컨테이너가 실행 중인지 확인 후 명령 실행
    master_container=$(docker ps -q -f name=redis-master-$i)
    replica_container=$(docker ps -q -f name=redis-replica-$i)
    
    if [ ! -z "$master_container" ]; then
        docker exec $master_container redis-cli FLUSHALL 2>/dev/null || true
        docker exec $master_container redis-cli CLUSTER RESET 2>/dev/null || true
    fi
    
    if [ ! -z "$replica_container" ]; then
        docker exec $replica_container redis-cli FLUSHALL 2>/dev/null || true
        docker exec $replica_container redis-cli CLUSTER RESET 2>/dev/null || true
    fi
done

# 클러스터 초기화
echo "클러스터 초기화 중..."
master1_container=$(docker ps -q -f name=redis-master-1)
if [ ! -z "$master1_container" ]; then
    docker exec $master1_container redis-cli --cluster create \
      redis-master-1:6379 redis-master-2:6379 redis-master-3:6379 \
      redis-replica-1:6379 redis-replica-2:6379 redis-replica-3:6379 \
      --cluster-replicas 1 --cluster-yes
else
    echo "redis-master-1 컨테이너를 찾을 수 없습니다."
    exit 1
fi

# 상태 확인
echo "클러스터 상태 확인:"
docker exec $master1_container redis-cli cluster info | grep cluster_state

echo "🎉 Redis 클러스터 배포 완료!"
echo "접속 정보:"
echo "   - Master: localhost:7001, 7002, 7003"
echo "   - Replica: localhost:7004, 7005, 7006"
echo "   - 사용법: redis-cli -c -p 7001"
