load("common/config.star", "create_backend_config")

def main():
    return {
        "backend_type": "s3",
        "config": create_backend_config("hello_ec2"),
    }
