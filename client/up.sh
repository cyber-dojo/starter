#!/bin/bash
set -e

# The --host is needed for IPv4 and IPv6 addresses

bundle exec rackup \
  --warn \
  --host 0.0.0.0 \
  --port 4528 \
  --server thin \
  --env production \
    config.ru
