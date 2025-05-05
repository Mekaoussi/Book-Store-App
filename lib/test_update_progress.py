
import requests
import json
from datetime import datetime

# Configuration
BASE_URL = "http://192.168.1.6:8000/bookstore"
        
token = "461462a11607b7813b8ee6afa1dc7ab807eb70ee"  # Using same token as other tests
headers = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
}

def test_update_progress():
    """Test the update_progress endpoint with various scenarios"""
    url = f"{BASE_URL}/update_progress/"
    
    test_cases = [
        {
            "name": "Valid progress update",
            "data": {"book_id": 330, "current_page": 50},
            "expected_status": 200
        },
        {
            "name": "Missing book_id",
            "data": {"current_page": 50},
            "expected_status": 400
        },
        {
            "name": "Missing current_page",
            "data": {"book_id": 330},
            "expected_status": 400
        },
        {
            "name": "Non-existent book",
            "data": {"book_id": 99999, "current_page": 50},
            "expected_status": 404
        },
        {
            "name": "Zero page progress",
            "data": {"book_id": 330, "current_page": 0},
            "expected_status": 200
        },
        {
            "name": "Last page progress",
            "data": {"book_id": 330, "current_page": 285},
            "expected_status": 200
        },
        {
            "name": "Progress beyond book length",
            "data": {"book_id": 330, "current_page": 300},
            "expected_status": 400
        },
        {
            "name": "Negative page number",
            "data": {"book_id": 330, "current_page": -1},
            "expected_status": 400
        },
        {
            "name": "Invalid page type (string)",
            "data": {"book_id": 330, "current_page": "not_a_number"},
            "expected_status": 400
        },
        {
            "name": "Invalid page type (float)",
            "data": {"book_id": 330, "current_page": 50.5},
            "expected_status": 400
        },
        {
            "name": "Invalid book_id type",
            "data": {"book_id": "not_a_number", "current_page": 50},
            "expected_status": 400
        }
    ]

    print("\nStarting Update Progress API Tests...")
    print("=" * 50)

    for test_case in test_cases:
        print(f"\nTest: {test_case['name']}")
        print("-" * 30)
        
        try:
            response = requests.post(
                url,
                headers=headers,
                json=test_case['data']
            )
            
            print(f"Status Code: {response.status_code} (Expected: {test_case['expected_status']})")
            print("Response:", response.json())
            
            # Validate response structure for successful cases
            if response.status_code == 200:
                data = response.json()
                required_fields = ['message', 'current_page', 'progress_percent']
                
                print("\nValidating response structure:")
                for field in required_fields:
                    if field in data:
                        print(f"✓ {field} present")
                    else:
                        print(f"❌ Missing {field}")
                
                # Validate progress percentage is between 0 and 100
                if 'progress_percent' in data:
                    progress = data['progress_percent']
                    if 0 <= progress <= 100:
                        print(f"✓ Progress percentage valid: {progress}%")
                    else:
                        print(f"❌ Invalid progress percentage: {progress}%")
            
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
        
        print("-" * 30)

def test_unauthenticated_access():
    """Test accessing endpoint without authentication"""
    url = f"{BASE_URL}/update_progress/"
    
    print("\nTesting update progress without authentication...")
    try:
        response = requests.post(
            url,
            json={"book_id": 330, "current_page": 50}
        )
        print(f"Status Code: {response.status_code}")
        print("Response:", response.text)
    except Exception as e:
        print(f"Request failed: {e}")

def test_invalid_token():
    """Test with invalid authentication token"""
    url = f"{BASE_URL}/update_progress/"
    invalid_headers = {
        "Authorization": "Token invalid_token_here",
        "Content-Type": "application/json"
    }
    
    print("\nTesting update progress with invalid token...")
    try:
        response = requests.post(
            url,
            headers=invalid_headers,
            json={"book_id": 330, "current_page": 50}
        )
        print(f"Status Code: {response.status_code}")
        print("Response:", response.text)
    except Exception as e:
        print(f"Request failed: {e}")

def run_all_tests():
    """Run all test cases"""
    print("Starting Update Progress API Tests...")
    print("=" * 50)
    
    test_update_progress()
    test_unauthenticated_access()
    test_invalid_token()
    
    print("\nTests completed!")
    print("=" * 50)

if __name__ == "__main__":
    run_all_tests()

