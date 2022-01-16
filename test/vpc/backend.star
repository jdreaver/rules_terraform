load("common/config.bzl", "create_backend_config")

def main():
    return {
        "backend_type": "s3",
        "config": create_backend_config("vpc"),
        "variable_name": "vpc",
    }
