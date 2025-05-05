import requests
import json

token = "d295acd7913c3a4e36a3e051ac44d324fc70eaba"
protected_url = "http://192.168.1.2:8000/bookstore/sign_in/"  # Corrected URL!

headers = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
}

body = {
    "email": "hisoka.ha29@gmail.com",
    "password": "crowpills"
}

try:
    response = requests.post(protected_url, headers=headers, data=json.dumps(body))
    response.raise_for_status()

    print(f"Request successful! Status code: {response.status_code}")

    # Extract the JSON data from the response
    try:
        data = response.json()
        print("Response data:", data)

        # Access specific data elements (adjust keys based on your API's response)
        token_from_response = data.get("token")
        user_data = data.get("user")

        if token_from_response:
            print("Token from response:", token_from_response)
        if user_data:
            print("User data:", user_data)
            print("Username:", user_data.get("username"))
            print("Email:", user_data.get("email"))

    except json.JSONDecodeError:
        print("Response did not contain valid JSON.")

except requests.exceptions.HTTPError as e:
    print(f"Request failed! Status code: {e.response.status_code}")
except requests.exceptions.RequestException as e:
    print(f"An unexpected error occurred: {e}")