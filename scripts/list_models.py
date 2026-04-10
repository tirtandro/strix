from google.cloud import aiplatform

def list_models():
    aiplatform.init(project="strix-project-marshal", location="us-central1")
    models = aiplatform.Model.list()
    for model in models:
        print(f"Model: {model.display_name}, ID: {model.resource_name}")

if __name__ == "__main__":
    list_models()
