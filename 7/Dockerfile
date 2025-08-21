FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnucobol4 \
    libcob4 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY app.py index.html main.cob ./
COPY requirements.txt ./

RUN touch accounts.txt
COPY accounts.txt ./ 

RUN pip install --no-cache-dir -r requirements.txt

RUN cobc -x -o main main.cob

RUN touch input.txt output.txt temp.txt

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]