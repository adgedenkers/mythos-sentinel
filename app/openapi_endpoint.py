from flask import Blueprint, jsonify, send_file
import yaml
import os

openapi_bp = Blueprint("openapi", __name__)

@openapi_bp.route("/openapi.json", methods=["GET"])
def openapi_json():
    with open("/opt/mythos-documentation/api/openapi.yaml") as f:
        spec = yaml.safe_load(f)
    return jsonify(spec)
