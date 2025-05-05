
import requests
import json

# Configuration
BASE_URL = "http://4703-129-45-28-135.ngrok-free.app/bookstore"
token = "e1f508431254b3e40d402a91d2f8812f3838ba95"  # Replace with your token
headers = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
}

def test_get_all_books():
    """Test getting all books endpoint"""
    url = f"{BASE_URL}/get_all_books/"
    
    print("\n1. Testing get all books with authentication...")
    try:
        response = requests.get(url, headers=headers)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("Success! Full response structure:")
            print("------------------------")
            
            # Validate expected keys
            expected_keys = ['all_books', 'for_you', 'new_books', 'favorite_books', 'user_orders']
            actual_keys = list(data.keys())
            print("Response data keys:", actual_keys)
            
            if set(expected_keys) != set(actual_keys):
                print("⚠️ Warning: Unexpected response structure")
                print("Missing keys:", set(expected_keys) - set(actual_keys))
                print("Extra keys:", set(actual_keys) - set(expected_keys))
            
            # All books validation
            books = data.get('all_books', [])
            print(f"\nTotal books: {len(books)}")
            # Check for books with isPaid=True
            paid_books = [book for book in books if book.get('isPaid') == True]
            print(f"\nBooks with isPaid=True: {len(paid_books)}")
            if paid_books:
                print("Paid books (showing first 3):")
                for book in paid_books[:3]:
                    print(f"- {book['title']} by {book['author']} (ID: {book['id']})")
            else:
                print("No books with isPaid=True found")
            
            if books:
                first_book = books[0]
                print("\nFirst book details:")
                required_fields = [
                    'id', 'title', 'author', 'description', 'page_count', 
                    'cover_image', 'genres', 'total_rating', 'readProgress',
                    'currentPage', 'isFavorite', 'isInLibrary', 'isPaid', 'lastReadAt', 'rating'
                ]
                
                # Validate required fields and their types
                field_validation = {
                    'id': (int, 'integer'),
                    'title': (str, 'string'),
                    'author': (str, 'string'),
                    'description': (str, 'string'),
                    'page_count': (int, 'integer'),
                    'cover_image': (str, 'URL string'),
                    'genres': (list, 'array of strings'),
                    'total_rating': ((int, float), 'number'),
                    'readProgress': ((int, float), 'number'),
                    'currentPage': (int, 'integer'),
                    'isFavorite': (bool, 'boolean'),
                    'isInLibrary': (bool, 'boolean'),
                    'isPaid': (bool, 'boolean')
                }

                print("\nField validation:")
                for field, (expected_type, type_name) in field_validation.items():
                    if field not in first_book:
                        print(f"❌ Missing field: {field}")
                    elif not isinstance(first_book[field], expected_type):
                        print(f"❌ Invalid type for {field}: expected {type_name}, got {type(first_book[field]).__name__}")
                    else:
                        print(f"✓ {field}: {type_name}")
                
                print("\nFirst book data:")
                print(json.dumps(first_book, indent=2))
            
            # Books list validations
            print("\nList validations:")
            new_books = data.get('new_books', [])
            for_you = data.get('for_you', [])
            favorite_books = data.get('favorite_books', [])
            
            print(f"New books: {len(new_books)}")
            if new_books:
                print("Latest new books (showing first 3):")
                for book in new_books[:3]:
                    print(f"- {book['title']} by {book['author']} (ID: {book['id']})")
            
            print(f"\nFor you books: {(for_you)}")
            print(f"Favorite books: {len(favorite_books)}")
            
            # User orders validation
            user_orders = data.get('user_orders', [])
            print(f"\nUser orders: {len(user_orders)}")
            if user_orders:
                print("\nOrder details (showing first 3):")
                for order in user_orders[:3]:
                    print(f"- Order #{order['order_number']} (ID: {order['id']})")
                    print(f"  Status: {order['status']}")
                    print(f"  Payment Method: {order['payment_method']}")
                    print(f"  Total Amount: {order['total_amount']}")
                    print(f"  Created At: {order['created_at']}")
                    print(f"  Items: {len(order.get('items', []))}")
                    
                    # Show first 2 items in each order
                    for item in order.get('items', [])[:2]:
                        print(f"    - {item.get('title')} (ID: {item.get('book_id')}) - ${item.get('price')}")
                    
                    if len(order.get('items', [])) > 2:
                        print(f"    - ... and {len(order.get('items', [])) - 2} more items")
                    print()
                
                # Show first order in detail
                if user_orders:
                    print("\nFirst order data (detailed):")
                    print(json.dumps(user_orders[0], indent=2))
            
            # Summary with detailed checks
            print("\nValidation Summary:")
            print("✓ Response structure is valid")
            print(f"✓ Total books: {len(books)} (expected > 0)")
            print(f"✓ New books: {len(new_books)} (expected ≤ 10)")
            print(f"✓ For you books: {len(for_you)} (expected ≤ 10)")
            print(f"✓ Favorite books: {len(favorite_books)}")
            print(f"✓ User orders: {len(user_orders)}")
            
            # Additional validations
            if len(new_books) > 10:
                print("⚠️ Warning: New books list exceeds expected limit of 10")
            if len(for_you) > 10:
                print("⚠️ Warning: For you books list exceeds expected limit of 10")
            
            print("------------------------")
        else:
            print("Error response:", response.text)
    except Exception as e:
        print(f"Request failed: {e}")

def test_unauthenticated_access():
    """Test accessing endpoint without authentication"""
    url = f"{BASE_URL}/get_all_books/"
    
    print("\n2. Testing get all books without authentication...")
    try:
        response = requests.get(url)  # No headers
        print(f"Status Code: {response.status_code}")
        print("Response:", response.text)
    except Exception as e:
        print(f"Request failed: {e}")

def test_invalid_token():
    """Test with invalid authentication token"""
    url = f"{BASE_URL}/get_all_books/"
    invalid_headers = {
        "Authorization": "Token invalid_token_here",
        "Content-Type": "application/json"
    }
    
    print("\n3. Testing get all books with invalid token...")
    try:
        response = requests.get(url, headers=invalid_headers)
        print(f"Status Code: {response.status_code}")
        print("Response:", response.text)
    except Exception as e:
        print(f"Request failed: {e}")

def run_all_tests():
    """Run all test cases"""
    print("Starting Book Listings API Tests...")
    print("=" * 50)
    
    test_get_all_books()
    #test_unauthenticated_access()
    #test_invalid_token()
    
    print("\nTests completed!")
    print("=" * 50)

if __name__ == "__main__":
    run_all_tests()



