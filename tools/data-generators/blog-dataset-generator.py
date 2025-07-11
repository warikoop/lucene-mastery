import json
import random
from faker import Faker

fake = Faker()

def generate_blog_post(post_id):
    return {
        "id": f"blog-{post_id}",
        "title": fake.sentence(nb_words=6),
        "content": fake.text(max_nb_chars=2000),
        "category": random.choice(['Technology', 'Business', 'Lifestyle', 'Science', 'Health']),
        "tags": [fake.word() for _ in range(random.randint(2, 5))],
        "author": fake.name(),
        "published_at": fake.iso8601(),
        "indexed_at": fake.iso8601(),
        "popularity_score": round(random.uniform(1, 100), 2),
        "engagement_score": round(random.uniform(1, 100), 2),
        "url": fake.uri()
    }

if __name__ == "__main__":
    num_posts = 20000
    dataset = [generate_blog_post(i) for i in range(num_posts)]
    
    with open('../../data/blog-posts/20k-blog-dataset.json', 'w') as f:
        json.dump(dataset, f, indent=2)
        
    print(f"Generated {num_posts} blog posts and saved to data/blog-posts/20k-blog-dataset.json")
