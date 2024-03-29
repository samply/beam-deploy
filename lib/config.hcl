storage "raft" {
  path    = "/vault/file"
  node_id = "node1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
  http_idle_timeout = "30s"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://127.0.0.1:8200"
ui = true
