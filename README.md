<div align="center">

<img width="75" alt="DTalks Logo" src="https://github.com/user-attachments/assets/8901ef46-86b0-44d8-b9f5-d32f831a5651" />

<h1>DTalks Infrastructure</h1>

<p><em>DTalks 웹 서비스를 위한 인프라 구성 및 배포 자동화 리포지토리입니다</em></p>

<p>
  <img src="https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white" alt="Redis"/>
  <img src="https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white" alt="Nginx"/>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
<br>
  <img src="https://img.shields.io/badge/개발기간-2025.07~2025.08-7D57C1?style=for-the-badge&logo=github&logoColor=white" alt="개발기간"/>
</p>

</div>

<div align="left">

<br>

### 🚀 빠른 시작

**1. Redis 클러스터 배포 (Docker Compose)**

```bash
cd redis-cluster-compose
./deploy.sh
```

**2. Redis 클러스터 배포 (Docker Swarm)**

```bash
cd redis-cluster-stack
./deploy.sh
```

**3. Nginx + Spring Boot 환경 구성**

```bash
cd nginx-spring
# nginx.conf 설정 후 Nginx 실행
docker run -d -p 80:80 -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf nginx:latest
```

</div> 
