import json
import random
from faker import Faker
import datetime

fake = Faker()

def generate_apache_log():
    return {
        "timestamp": datetime.datetime.now().isoformat(),
        "client_ip": fake.ipv4(),
        "request": f"{random.choice(['GET', 'POST', 'PUT', 'DELETE'])} {fake.uri_path()} HTTP/1.1",
        "status_code": random.choice([200, 201, 400, 401, 404, 500]),
        "response_size": random.randint(100, 50000),
        "user_agent": fake.user_agent()
    }

def generate_app_log():
    return {
        "timestamp": datetime.datetime.now().isoformat(),
        "level": random.choice(['INFO', 'WARN', 'ERROR', 'DEBUG']),
        "service": random.choice(['auth-service', 'payment-service', 'checkout-service', 'shipping-service']),
        "message": fake.sentence(nb_words=10)
    }

if __name__ == "__main__":
    num_logs = 10000
    
    apache_logs = [generate_apache_log() for _ in range(num_logs)]
    with open('../../data/logs/apache-access-logs.json', 'w') as f:
        for log in apache_logs:
            f.write(json.dumps(log) + '\n')
            
    app_logs = [generate_app_log() for _ in range(num_logs)]
    with open('../../data/logs/application-logs.json', 'w') as f:
        for log in app_logs:
            f.write(json.dumps(log) + '\n')

    print(f"Generated {num_logs} Apache and application logs.")
