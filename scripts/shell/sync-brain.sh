#!/bin/bash

# Synchronizes my org brain with github

cd ~/org
git pull
git add .
git commit -m "sync"
git push
