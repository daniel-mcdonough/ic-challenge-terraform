resource "kubernetes_namespace" "intercax" {
  metadata {
    annotations = {
      name = "intercax"
    }

    labels = {
      environment = "dev"
    }

    name = "intercax"
  }
}



resource "kubernetes_secret" "intercax_postgres_secrets" {
  metadata {
    name = "postgres-secret"
    
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}

resource "kubernetes_persistent_volume_claim" "ic_postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "longhorn"
  }
}


resource "kubernetes_stateful_set" "ic_postgres_statefulset" {
  metadata {
    name = "postgres"
    
  }

  spec {
    selector {
      match_labels = {
        app = "postgres"
      }
    }

    service_name = "postgres"
    replicas     = 1

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:latest"

          env_from {
            secret_ref {
              name = kubernetes_secret.intercax_postgres_secrets.metadata[0].name
            }
          }
 
         env {
             name  = "PGDATA"
             value = "/var/lib/postgresql/data/intercax" 
           }

          port {
            container_port = 5432
          }

          liveness_probe {
            exec {
              command = ["psql", "-U", "postgres", "-c", "SELECT 1;"]
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          volume_mount {
            name       = "init-scripts"
            mount_path = "/docker-entrypoint-initdb.d/"
          }

          volume_mount {
            mount_path = "/var/lib/postgresql/data/"
            name       = "postgres-storage"
          }
        }
        volume {
          name = "init-scripts"

          config_map {
            name = kubernetes_config_map.postgres_init.metadata[0].name
          }
        }
        volume {
          name = "postgres-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ic_postgres_pvc.metadata[0].name
          }
        }
      }
    }


  }
}



resource "kubernetes_service" "service_postgres" {
  metadata {
    name = "postgres"
    
  }

  spec {
    port {
      port        = 5432
      target_port = 5432
    }

    selector = {
      app = "postgres"
    }

    type = "ClusterIP"
  }
}


resource "random_password" "exporter_password" {
  length           = 16
  special          = false
}


resource "kubernetes_config_map" "postgres_init" {
  metadata {
    name = "postgres-init"
    
  }

  data = {
    "create_user.sh" = <<-EOT
    #!/bin/bash
    set -e
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
      CREATE USER exporter WITH PASSWORD '${random_password.exporter_password.result}';
      GRANT pg_monitor TO exporter;
      EOSQL
    EOT
  }
}

#This likely needs to be a count for each postgres deployed
resource "kubernetes_deployment" "postgres_exporter" {
  metadata {
    name = "postgres-exporter"
    
    labels = {
      app = "postgres-exporter"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-exporter"
        }
      }

      spec {
        container {
          name  = "postgres-exporter"
          image = "prometheuscommunity/postgres-exporter:latest"
          port {
            container_port = 9187
          }
          env {
            name  = "DATA_SOURCE_NAME"
            value = "postgresql://exporter:${random_password.exporter_password.result}@postgres:5432/postgres?sslmode=disable"
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "postgres_exporter" {
  metadata {
    name = "postgres-exporter"
  }

  spec {
    selector = {
      app = "postgres-exporter"
    }

    port {
      name        = "metrics"
      port        = 9187
      target_port = 9187
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "postgres_exporter_np" {
  metadata {
    name = "postgres-exporter-np"
  }

  spec {
    selector = {
      app = "postgres-exporter"
    }

    port {
      port        = 9187
      target_port = 9187
      node_port = 30001
    }

    type = "NodePort"
  }
}
