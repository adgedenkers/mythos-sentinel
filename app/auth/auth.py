from fastapi import Header, HTTPException
import yaml
from pathlib import Path

USERS_FILE = Path("/opt/mythos-sentinel/app/core/users.yaml")

def load_users():
    with open(USERS_FILE, "r") as f:
        data = yaml.safe_load(f)
    return {user["api_key"]: user for user in data.get("users", [])}

def get_api_key(x_api_key: str = Header(...)):
    users = load_users()
    if x_api_key not in users:
        raise HTTPException(status_code=401, detail="Invalid API Key")
    return x_api_key

def get_user_data(api_key: str):
    users = load_users()
    return users.get(api_key)
