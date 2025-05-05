
import requests
import json

# Configuration
token = "a5a797c87410a01afd7a21242cdd249dbf46313a"
url = "http://192.168.1.6:8000/bookstore/get_all_books/"
headers = {"Authorization": f"Token {token}"}

try:
    response = requests.get(url, headers=headers, timeout=5)
    
    if response.status_code == 200:
        data = response.json()
        with open('api_response.json', 'w') as f:
            json.dump(data, f, indent=2)
        print("Success! Data saved to api_response.json")
    else:
        print(f"Error: Status code {response.status_code}")
        
except Exception as e:
    print(f"Error: {e}")
