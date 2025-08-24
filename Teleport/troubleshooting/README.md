# Teleport Trouble Shooting

## Windows의 경우 [teleport kubeconfig 인증서 export 명령어]

### <code>\$env:KUBECONFIG="$HOME\teleport-kubeconfig.yaml"</code>


## Kubernetes API Server와 연결이 안되는 경우

### 1. 인증서가 Valid한지 확인
### 2. API Sever가 Public하거나 현재 Network 망에서 접근 가능한지 확인
### 3. 정확한 K8S Group 또는 User를 설정했는지 확인

## ERROR: ssh: cert is not yet valid 오류 [TSH 로그인 시]

### Teleport 서버 및 사용자 기기 Time 확인할 것
- Linux -> date;timedatectl
- Windows -> Get-Date

### 동기화 방법
- Linux -> sudo ntpdate time.nist.gov 또는 sudo timedatectl set-ntp true
- Windows -> w32tm /resync

! 만약 Windows에서 다음 문제 발생 시 "다음 오류가 발생했습니다. 서비스가 시작되지 않았습니다." <code>net start w32time</code>로 해결
