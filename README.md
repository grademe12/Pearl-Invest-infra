# Pearl-Invest-infra

[Pearl Invest](https://github.com/grademe12/Pearl-Invest) 홈랩의 K3s 클러스터에 Teleport로 접근할 때 쓰는 쿠버네티스 RBAC 설정입니다. (2025.09)

포트폴리오 설명: <https://woosupar.dev/projects/pearl-invest/>

## 왜 필요한가

Pearl Invest v2.0에서는 관리자가 라즈베리파이의 K3s에 직접 kubeconfig로 붙지 않고, EC2에서 돌아가는 Teleport 클러스터를 거쳐 들어갑니다. Teleport가 사용자를 인증하고 단기 인증서를 발급하면, 클러스터 안의 Teleport 에이전트가 그 사용자를 **대신해서(impersonate)** 쿠버네티스 API에 요청을 보냅니다.

그래서 권한이 두 겹으로 필요합니다.

1. 에이전트가 사용자를 대신할 수 있는 권한
2. 대신하는 그 사용자(그룹)가 실제로 할 수 있는 일의 범위

## 요청이 흐르는 순서

```
관리자 ──▶ Teleport (EC2)          사용자 인증, 역할 확인, 단기 인증서
              │
              ▼
          teleport-agent (K3s 안의 ServiceAccount)
              │  사용자와 그룹을 impersonate
              ▼
          Kubernetes RBAC           impersonate된 그룹의 권한으로 허용 여부 판단
```

## 파일

| 파일 | 내용 |
|---|---|
| `rbac.yaml` | `teleport-agent` ServiceAccount의 권한. 사용자, 그룹, ServiceAccount를 impersonate하고, 파드와 `pods/exec`, `pods/log`, `pods/portforward`를 다루고, 네임스페이스, 노드, 서비스를 조회합니다. |
| `rbac-teleport.yaml` | Teleport 역할과 연결된 `auth-api-group` 그룹의 권한. 파드 조회와 생성, 네임스페이스 조회, `pods/exec`, `pods/log` |

`pods/exec`처럼 하위 리소스는 따로 적어야 하고, exec에는 `create`와 `get`이 둘 다 필요했습니다.

## 적용

Teleport 에이전트는 Helm으로 설치하고, RBAC만 이 저장소에서 적용합니다.

```bash
kubectl apply -f rbac.yaml
kubectl apply -f rbac-teleport.yaml
```

`rbac.yaml`의 ServiceAccount 이름과 네임스페이스는 Helm이 만든 이름과 같아야 합니다.

## 해 보고 알게 된 것

- 처음에는 에이전트를 Docker 이미지와 YAML로 직접 배포했지만, Helm 차트를 쓰면 그 과정이 필요 없어서 Helm으로 바꿨습니다. 다만 Teleport 클러스터에 연결된 뒤의 역할 설정은 직접 해야 합니다.
- 파드 이름을 기준으로 한 접근 제어는 동작했고, 라벨을 기준으로 한 접근 제어는 원인을 찾지 못한 채 남아 있습니다.
