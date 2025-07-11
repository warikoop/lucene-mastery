import json
import random
from faker import Faker

fake = Faker()

def generate_product(product_id):
    return {
        "product_id": f"prod-{product_id}",
        "product_name": fake.ecommerce_name(),
        "description": fake.text(max_nb_chars=500),
        "price": round(random.uniform(10, 1000), 2),
        "category": fake.ecommerce_category(),
        "brand": fake.company(),
        "in_stock": random.choice([True, False]),
        "created_at": fake.iso8601()
    }

if __name__ == "__main__":
    num_products = 5000
    dataset = [generate_product(i) for i in range(num_products)]
    
    with open('../../data/e-commerce/products-dataset.json', 'w') as f:
        json.dump(dataset, f, indent=2)
        
    print(f"Generated {num_products} products and saved to data/e-commerce/products-dataset.json")
