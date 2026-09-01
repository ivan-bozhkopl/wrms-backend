FROM python:3.14-slim

WORKDIR /app

COPY . .

RUN pip install -e .

CMD ["python", "-m", "wrms_backend.main"]