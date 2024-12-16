# Python 3.9 이미지 사용
FROM python:3.9-slim

# 작업 디렉토리 설정
WORKDIR /app

# 필요한 파일 복사
COPY requirements.txt requirements.txt

# 종속성 설치
RUN pip install --no-cache-dir -r requirements.txt

# 실행 파일 복사
COPY app.py app.py
COPY .env .env

# Uvicorn 실행, 0.0.0.0:8000 포트로 실행
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
