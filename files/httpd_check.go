package main

import (
    "net/http"
    "os"
    "time"
)

func main() {
    url := "http://127.0.0.1:8000/"
    timeout := 10 * time.Second // タイムアウト設定

    client := http.Client{
        Timeout: timeout,
    }

    resp, err := client.Get(url)
    if err != nil {
        os.Exit(1)
    }
    defer resp.Body.Close()

    if resp.StatusCode == http.StatusOK {
        os.Exit(0)
    } else {
        os.Exit(1)
    }
}
