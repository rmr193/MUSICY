# 🎶 MUSICY

MUSICY is a simple web-based music application. 

## 💻 Local Development

Run the app using
```sh
$ pip3 install -r requirements.txt
$ python3 -m uvicorn app:app --reload
```

Navigate to: `http://127.0.0.1:8000/web` to get started.

## 🐳 Docker Deployment

Deploy the app locally using the following Docker-Compose stack: 

```yaml
services:
  musicy:
    build: .
    container_name: musicy
    ports:
      - "8000:8000" # External port can be changed
    restart: unless-stopped
```

Navigate to: `http://SERVER_IP:8000/web` to get started.
# MUSICY
