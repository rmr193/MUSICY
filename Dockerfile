FROM python:alpine

WORKDIR /MUSICY

COPY app.py app.py
COPY requirements.txt requirements.txt
COPY static/ static/

EXPOSE 8000

RUN apk add g++ make libffi-dev openssl-dev --no-cache

RUN pip3 install -r requirements.txt

CMD ["python", "-m", "uvicorn", "app:app" , "--host", "0.0.0.0", "--port", "8000"]