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

data "keepass_entry" "intercax_postgres" {
  path = "Root/intercax/postgres"
}



resource "kubernetes_secret" "intercax_postgres_secrets" {
  metadata {
    name = "postgres-secret"
    namespace = kubernetes_namespace.intercax.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = data.keepass_entry.intercax_postgres.password
  }
}

resource "kubernetes_persistent_volume_claim" "ic_postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.intercax.metadata[0].name
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
    namespace = kubernetes_namespace.intercax.metadata[0].name
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
            mount_path = "/var/lib/postgresql/data/intercax"
            name       = "postgres-storage"
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

resource "random_password" "exporter_password" {
  length           = 16
  special          = false
}


resource "kubernetes_config_map" "postgres_exporter_user_sql" {
  metadata {
    name = "postgres-exporter-user-sql"
  }

  data = {
    "create_user.sql" = <<-EOT
      CREATE USER exporter WITH PASSWORD '${random_password.exporter_password.result}';
      GRANT pg_monitor TO exporter;
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
            value = "postgresql://exporter:@postgres:5432/<dbname>?sslmode=disable"
          }
        }
      }
    }
  }
}
