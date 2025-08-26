# Menggunakan base image python
FROM python:3.11-slim

# Install GnuCOBOL dan dependensi
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnucobol4 \
    libcob4 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Salin semua file yang dibutuhkan
COPY app.py index.html main.cob ./
COPY requirements.txt ./
COPY accounts.txt ./

# Install dependensi Python
RUN pip install --no-cache-dir -r requirements.txt

# Compile program COBOL
RUN cobc -x -o main main.cob -free

# Buat file-file yang dibutuhkan
RUN touch input.txt output.txt temp.txt

# Salin dan berikan izin eksekusi untuk start script
COPY start.sh .
RUN chmod +x ./start.sh

# Expose port untuk aplikasi web
EXPOSE 8000

# Jalankan start script sebagai entrypoint
CMD ["./start.sh"]