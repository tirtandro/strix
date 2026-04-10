import requests
import google.auth
import google.auth.transport.requests

def list_publisher_models():
    credentials, project = google.auth.default()
    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    
    region = "us-central1"
    url = f"https://{region}-aiplatform.googleapis.com/v1/projects/{project}/locations/{region}/publishers/google/models"
    
    headers = {
        "Authorization": f"Bearer {credentials.token}",
        "Content-Type": "application/json"
    }
    
    print(f"Checking URL: {url}")
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        models = response.json().get("models", [])
        for m in models:
            name = m.get("name", "")
            if "gemini" in name:
                print(f"Found Gemini Model: {name}")
    else:
        print(f"Error {response.status_code}: {response.text}")

if __name__ == "__main__":
    list_publisher_models()
