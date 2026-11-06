#!/bin/bash

echo "Pushing quay.io/lccrittell/containers-capstone:podman image to quay repo"

podman push quay.io/lccrittell/containers-capstone:podman

echo "Push successful!"

exit 0
