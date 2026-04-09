# Inisialisasi Infrastruktur GCP untuk Strix

Ikuti langkah-langkah berikut untuk menyiapkan GCP sebelum menjalankan deployment otomatis via GitHub Actions.

## 1. Persiapan Project & API

Pastikan Anda sudah login dan memilih project yang benar:

```bash
gcloud auth login
gcloud config set project strix-project-marshal
```

Aktifkan API yang diperlukan:

```bash
gcloud services enable artifactregistry.googleapis.com run.googleapis.com aiplatform.googleapis.com iam.googleapis.com
```

## 2. Membuat Artifact Registry

Tempat penyimpanan image Docker:

```bash
gcloud artifacts repositories create strix-repo \
    --repository-format=docker \
    --location=us-central1 \
    --description="Docker repository for Strix Agent"
```

## 3. Membuat Service Account (SA) untuk GitHub Actions

Buat SA khusus:

```bash
gcloud iam service-accounts create strix-deployer \
    --display-name="Strix Deployment Service Account"
```

Berikan izin yang diperlukan:

```bash
# Izin untuk mangelola Cloud Run
gcloud projects add-iam-policy-binding strix-project-marshal \
    --member="serviceAccount:strix-deployer@strix-project-marshal.iam.gserviceaccount.com" \
    --role="roles/run.admin"

# Izin untuk Artifact Registry
gcloud projects add-iam-policy-binding strix-project-marshal \
    --member="serviceAccount:strix-deployer@strix-project-marshal.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"

# Izin untuk Vertex AI
gcloud projects add-iam-policy-binding strix-project-marshal \
    --member="serviceAccount:strix-deployer@strix-project-marshal.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

# Izin tambahan untuk IAM
gcloud projects add-iam-policy-binding strix-project-marshal \
    --member="serviceAccount:strix-deployer@strix-project-marshal.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

Dapatkan kunci SA (JSON) untuk disimpan di GitHub Secrets:

```bash
gcloud iam service-accounts keys create gcp-sa-key.json \
    --iam-account=strix-deployer@strix-project-marshal.iam.gserviceaccount.com
```

## 4. Konfigurasi GitHub Secrets

Simpan isi `gcp-sa-key.json` dan `strix-project-marshal` sebagai GitHub Secrets:
*   `GCP_SA_KEY`: (Isi file JSON)
*   `GCP_PROJECT_ID`: strix-project-marshal
