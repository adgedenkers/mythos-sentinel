#!/bin/bash
export PYTHONPATH=/opt/mythos-sentinel
source /opt/mythos-sentinel/.venv/bin/activate
pytest /opt/mythos-sentinel/tests
