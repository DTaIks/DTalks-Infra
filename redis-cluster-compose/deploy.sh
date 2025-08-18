#!/bin/bash

echo "🚀 Redis 클러스터 배포"

# 기존 컨테이너 정리
echo "기존 컨테이너 정리 중..."
docker compose down -v 2>/dev/null || true

# 새 컨테이너 시작
echo "Redis 클러스터 컨테이너 시작 중..."
docker compose up -d

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
        docker exec $master_container redis-cli CLUSTER RESET HARD 2>/dev/null || true
    fi
    
    if docker ps -q -f name=$replica_container | grep -q .; then
        docker exec $replica_container redis-cli FLUSHALL 2>/dev/null || true
        docker exec $replica_container redis-cli CLUSTER RESET HARD 2>/dev/null || true
    fi
done

# 클러스터 노드들이 완전히 리셋될 때까지 대기
echo "클러스터 리셋 대기 중..."
sleep 15

# 컨테이너 IP 주소 가져오기
echo "컨테이너 IP 주소 확인 중..."
MASTER1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master-1)
MASTER2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master-2)
MASTER3_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master-3)
REPLICA1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-replica-1)
REPLICA2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-replica-2)
REPLICA3_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-replica-3)

echo "컨테이너 IP들:"
echo "  Master1: $MASTER1_IP"
echo "  Master2: $MASTER2_IP"
echo "  Master3: $MASTER3_IP"
echo "  Replica1: $REPLICA1_IP"
echo "  Replica2: $REPLICA2_IP"
echo "  Replica3: $REPLICA3_IP"

# 클러스터 초기화
echo "클러스터 초기화 중..."
if docker ps -q -f name=redis-master-1 | grep -q .; then
    # 컨테이너 IP를 사용하여 클러스터 생성
    docker exec redis-master-1 redis-cli --cluster create \
      ${MASTER1_IP}:6379 ${MASTER2_IP}:6379 ${MASTER3_IP}:6379 \
      ${REPLICA1_IP}:6379 ${REPLICA2_IP}:6379 ${REPLICA3_IP}:6379 \
      --cluster-replicas 1 --cluster-yes
    
    if [ $? -eq 0 ]; then
        echo "클러스터 초기화 성공!"
    else
        echo "클러스터 초기화 실패. 재시도 중..."
        sleep 10
        
        # 재시도
        docker exec redis-master-1 redis-cli --cluster create \
          ${MASTER1_IP}:6379 ${MASTER2_IP}:6379 ${MASTER3_IP}:6379 \
          ${REPLICA1_IP}:6379 ${REPLICA2_IP}:6379 ${REPLICA3_IP}:6379 \
          --cluster-replicas 1 --cluster-yes
        
        if [ $? -ne 0 ]; then
            echo "클러스터 초기화 재시도 실패"
            exit 1
        fi
    fi
else
    echo "redis-master-1 컨테이너를 찾을 수 없습니다."
    exit 1
fi

# 클러스터 생성 후 대기
echo "클러스터 안정화 대기 중..."
sleep 20

# 상태 확인
echo "클러스터 상태 확인:"
docker exec redis-master-1 redis-cli cluster info | grep cluster_state
echo ""
echo "클러스터 노드 정보:"
docker exec redis-master-1 redis-cli cluster nodes

# 클러스터가 정상적으로 생성되었는지 검증
cluster_state=$(docker exec redis-master-1 redis-cli cluster info | grep cluster_state | cut -d: -f2)
cluster_size=$(docker exec redis-master-1 redis-cli cluster info | grep cluster_size | cut -d: -f2)

if [ "$cluster_state" = "ok" ] && [ "$cluster_size" -gt 1 ]; then
    echo ""
    echo "🎉 Redis 클러스터 배포 완료!"
    echo "클러스터 상태: $cluster_state"
    echo "클러스터 크기: $cluster_size"
else
    echo ""
    echo "클러스터 초기화 실패"
    echo "클러스터 상태: $cluster_state"
    echo "클러스터 크기: $cluster_size"
    exit 1
fi

echo ""
echo "접속 정보:"
echo "   - Master: localhost:7001, 7002, 7003"
echo "   - Replica: localhost:7004, 7005, 7006"
echo "   - 사용법: redis-cli -c -p 7001"
echo ""
echo "관리 명령어:"
echo "   - 시작: docker compose up -d"
echo "   - 중지: docker compose down"
echo "   - 로그: docker compose logs -f"
echo ""
echo "환경변수 설정:"
echo "   export SPRING_DATA_REDIS_CLUSTER_NODES=localhost:7001,localhost:7002,localhost:7003,localhost:7004,localhost:7005,localhost:7006"
echo "   export SPRING_DATA_REDIS_CLUSTER_MAX_REDIRECTS=5"
echo "   export SPRING_DATA_REDIS_TIMEOUT=5000"
