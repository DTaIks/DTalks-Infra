#!/bin/bash

echo "🚀 Redis 클러스터 배포"

# 기존 컨테이너 정리
echo "기존 컨테이너 정리 중..."
docker-compose down -v 2>/dev/null || true

# 새 컨테이너 시작
echo "Redis 클러스터 컨테이너 시작 중..."
docker-compose up -d

# 서비스 상태 확인 및 대기
echo "서비스 시작 대기 중..."
sleep 30

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
    master_container="redis-master-$i"
    replica_container="redis-replica-$i"
    
    if docker ps -q -f name=$master_container | grep -q .; then
        docker exec $master_container redis-cli FLUSHALL 2>/dev/null || true
        docker exec $master_container redis-cli CLUSTER RESET 2>/dev/null || true
    fi
    
    if docker ps -q -f name=$replica_container | grep -q .; then
        docker exec $replica_container redis-cli FLUSHALL 2>/dev/null || true
        docker exec $replica_container redis-cli CLUSTER RESET 2>/dev/null || true
    fi
done

# 클러스터 초기화
echo "클러스터 초기화 중..."
if docker ps -q -f name=redis-master-1 | grep -q .; then
    docker exec redis-master-1 redis-cli --cluster create \
      127.0.0.1:6379 127.0.0.1:6379 127.0.0.1:6379 \
      127.0.0.1:6379 127.0.0.1:6379 127.0.0.1:6379 \
      --cluster-replicas 1 --cluster-yes
else
    echo "redis-master-1 컨테이너를 찾을 수 없습니다."
    exit 1
fi

# 상태 확인
echo "클러스터 상태 확인:"
docker exec redis-master-1 redis-cli cluster info | grep cluster_state

echo "🎉 Redis 클러스터 배포 완료!"
echo "접속 정보:"
echo "   - Master: localhost:7001, 7002, 7003"
echo "   - Replica: localhost:7004, 7005, 7006"
echo "   - 사용법: redis-cli -c -p 7001"
echo ""
echo "관리 명령어:"
echo "   - 시작: docker-compose up -d"
echo "   - 중지: docker-compose down"
echo "   - 로그: docker-compose logs -f" 
