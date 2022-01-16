load("common/config.star", "create_backend_config")

def main():
    return {
        "backend_type": "s3",
        "config": create_backend_config("tf_state_bootstrap"),
    }
