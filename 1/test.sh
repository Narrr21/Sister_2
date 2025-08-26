#!/bin/bash

# ============================================
# Skrip Pengujian Otomatis untuk Server Assembly
# chmod +x terlebih dahulu
# ============================================

SERVER_URL="http://localhost:8080"
SERVER_BIN="./bin/server"

start_server() {
    echo "Memeriksa dan mematikan server yang sedang berjalan..."
    pkill server &>/dev/null
    sleep 1

    echo "Memulai server dari $SERVER_BIN di $SERVER_URL..."
    $SERVER_BIN > /dev/null 2>&1 &
    sleep 1
}

stop_server() {
    echo "Menghentikan server..."
    pkill server > /dev/null 2>&1
    sleep 1
}


test_get_index() {
    echo -n "Uji GET /..."
    curl -s "$SERVER_URL/" | grep "Welcome to the Assembly Server!" > /dev/null
    if [ $? -eq 0 ]; then
        echo " PASSED"
    else
        echo " FAILED"
        return 1
    fi
}

test_post_submit() {
    echo -n "Uji POST /submit..."
    curl -s -o /dev/null -w "%{http_code}" -X POST -d "text=Test from shell script" "$SERVER_URL/submit" | grep "302" > /dev/null
    if [ $? -eq 0 ]; then
        if [ -f "submitted.txt" ] && grep -q "Test from shell script" "submitted.txt"; then
            echo " PASSED"
        else
            echo " FAILED (File submitted.txt tidak dibuat atau konten salah)"
            return 1
        fi
    else
        echo " FAILED (Kode HTTP tidak sesuai)"
        return 1
    fi
}

test_put_content() {
    echo -n "Uji PUT /submitted.txt..."
    local content="Konten baru dari PUT."
    curl -s -o /dev/null -w "%{http_code}" -X PUT -d "$content" "$SERVER_URL/submitted.txt" | grep "201" > /dev/null
    if [ $? -eq 0 ]; then
        if [ -f "submitted.txt" ] && grep -q "$content" "submitted.txt"; then
            echo " PASSED"
        else
            echo " FAILED (Konten file tidak diganti)"
            return 1
        fi
    else
        echo " FAILED (Kode HTTP tidak sesuai)"
        return 1
    fi
}

test_delete_file() {
    echo -n "Uji DELETE /submitted.txt..."
    curl -s -o /dev/null -w "%{http_code}" -X DELETE "$SERVER_URL/submitted.txt" | grep "204" > /dev/null
    if [ $? -eq 0 ]; then
        if [ ! -f "submitted.txt" ]; then
            echo " PASSED"
        else
            echo " FAILED (File tidak dihapus)"
            return 1
        fi
    else
        echo " FAILED (Kode HTTP tidak sesuai)"
        return 1
    fi
}

test_404_not_found() {
    echo -n "Uji 404 Not Found..."
    curl -s -o /dev/null -w "%{http_code}" "$SERVER_URL/submitted.txt" | grep "404" > /dev/null
    if [ $? -eq 0 ]; then
        echo " PASSED"
    else
        echo " FAILED"
        return 1
    fi
}

echo "=========================================="
echo "      Mulai Rangkaian Pengujian Server      "
echo "=========================================="
start_server

test_get_index || exit 1
test_post_submit || exit 1
test_put_content || exit 1
test_delete_file || exit 1
test_404_not_found || exit 1

stop_server
echo "=========================================="
echo "    Semua Tes Selesai dan Berhasil!     "
echo "=========================================="