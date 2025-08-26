#!/bin/bash

# Jalankan proses kalkulasi bunga di background
echo "Starting interest calculation process in the background..."
./main --apply-interest &

# Jalankan server web FastAPI di foreground
echo "Starting web server..."
uvicorn app:app --host 0.0.0.0 --port 8000