# LatexOCR_Azure

## Demo video
https://youtu.be/MDS35h-oiCY

## Installation

```bash
python -m venv .venv

# PowerShell
.\.venv\Scripts\Activate.ps1

python -m pip install -r requirements.pure-python.txt

python app.py

# open browser
http://localhost:8000
```

### Notes (Windows)

- `requirements.pure-python.txt` intentionally avoids `pix2tex` so it can install on newer Python versions (e.g. 3.13). The server will run, but the **local** LaTeX-OCR engine may be unavailable (endpoints will return 503 for local engine).
- If you want the full local LaTeX-OCR pipeline (`pix2tex`), use Python 3.11 and install from `requirements.txt` instead.
- PDF conversion via `pdf2image` on Windows requires Poppler installed and available on PATH.

## Demo

Running the full pipeline:
```bash
curl.exe -X POST http://localhost:8000/api/simple-extract `
  -F "file=@test_descriptive_text.pdf" `
  -H "accept: application/json"
```

## Docker + Azure Container App


```bash
docker build -t latexocr:latest .

# one time testing command since the image is going to be public
docker run -p 8000:8000 -e DOCUMENT_INTELLIGENCE_ENDPOINT="" -e DOCUMENT_INTELLIGENCE_SUBSCRIPTION_KEY="" latexocr:latest

# access at http://localhost:8000
```

Pure-python oriented Dockerfile (no pix2tex):

```bash
docker build -f Dockerfile.pure-python -t latexocr:pure-python .
docker run --rm -p 8000:8000 latexocr:pure-python
```

Docker Compose (pure-python):

```bash
# build + start (runs in the background)
docker compose up -d --build

# follow logs
docker compose logs -f

# stop (keeps containers, so you can start again)
docker compose stop

# start again after stop
docker compose start

# restart quickly
docker compose restart

# stop and remove containers
docker compose down
```

## Kubernetes (Minikube)

Run the pure-python container on a local Kubernetes cluster.

Start Minikube:

```bash
minikube start
```

Optional (more stable than `kubectl port-forward`): expose the `NodePort` on your host.

This publishes the cluster's `nodePort: 30080` as host port `8000` (docker driver only):

```bash
# NOTE: port publishing is set when the minikube container is created.
# If your cluster already exists, do `minikube delete` first.
minikube start --driver=docker --container-runtime=containerd --ports=8000:30080 --listen-address=0.0.0.0
```

Build the image into Minikube (recommended):

```bash
minikube image build -t latexocr:pure-python -f Dockerfile.pure-python .
```

Deploy:

```bash
kubectl apply -f k8s/minikube.yaml
kubectl get pods
kubectl get svc latexocr
```

Note: `k8s/minikube.yaml` uses `replicas: 1` by default (pix2tex/torch is heavy and Minikube is usually single-node). Increase replicas only if you have enough CPU/RAM.

Access (local dev):

```bash
minikube service latexocr --url
```

Alternative access (bind on the host):

```bash
kubectl port-forward --address 0.0.0.0 svc/latexocr 8000:8000
```

If `kubectl port-forward` drops (e.g. "broken pipe"), run the auto-restarting helper:

```powershell
./scripts/k8s-port-forward.ps1 -LocalPort 8000 -Address 0.0.0.0
```

### After reboot

In most cases you do **not** need to redo the full setup.

- Start Docker Desktop (required for the `--driver=docker` Minikube driver)
- Start the cluster: `minikube start`
- Check pods: `kubectl get pods`
- Re-run access commands as needed:
  - `minikube service latexocr --url` (the URL can change)
  - `kubectl port-forward ...` (must be re-run every time)

You only need to rebuild/redeploy if you changed the code/image:

```bash
minikube image build -t latexocr:pure-python -f Dockerfile.pure-python .
kubectl rollout restart deployment/latexocr
```

If you run `minikube delete`, the cluster is removed and you will need to deploy again.

Cleanup:

```bash
kubectl delete -f k8s/minikube.yaml
```

```bash
docker tag latexocr:latest andialexandrescu/latexocr:latest
docker push andialexandrescu/latexocr:latest
```

```bash
docker pull andialexandrescu/latexocr:latest
docker run -p 8000:8000 andialexandrescu/latexocr:latest
```

When creating the container app, add environment variables:

DOCUMENT_INTELLIGENCE_ENDPOINT = ...
DOCUMENT_INTELLIGENCE_SUBSCRIPTION_KEY = ...

Then enable external ingress on port 8000

Updating docker image + container app
```bash
 $TAG="2026-01-23-1"
docker build -t andialexandrescu/latexocr:$TAG .

docker push andialexandrescu/latexocr:$TAG

$RESOURCE_GROUP="latex-ocr"
$CONTAINER_APP_NAME="latex-ocr-container-app"
az containerapp update `
  --name $CONTAINER_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --image "andialexandrescu/latexocr:$TAG"
```
