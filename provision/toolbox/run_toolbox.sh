#!/usr/bin/env bash
podman run --network host --no-hosts --pid host --privileged -v /dev:/dev -v /sys:/sys -it toolbox-like