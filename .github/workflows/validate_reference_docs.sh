#!/bin/bash
bundle exec puppet strings generate --format markdown
if ! git diff --exit-code; then
    echo
    echo ERROR: Reference docs are outdated.
    echo
    echo Use "bundle exec puppet strings generate --format markdown" from repo root to update reference docs. 
    echo
    exit 1
fi
