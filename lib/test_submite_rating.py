
import requests
import json

token = "461462a11607b7813b8ee6afa1dc7ab807eb70ee"
protected_url = "http://192.168.1.6:8000/bookstore/submit_rating/"
headers = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
}

# Test cases
test_cases = [
    {'book': 331, 'rating': 4.5},  # Valid rating
    {'book': 331, 'rating': 6.0},  # Invalid rating > 5
    {'book': 331, 'rating': -1},   # Invalid rating < 0
    {'book': 999, 'rating': 4.0},  # Non-existent book
    {'rating': 4.0},               # Missing book ID
    {'book': 331},                 # Missing rating
]

for test_case in test_cases:
    print("\nTesting with:", test_case)
    try:
        response = requests.post(protected_url, headers=headers, json=test_case)
        print(f"Status Code: {response.status_code}")
        print("Response:", response.json())
        
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
