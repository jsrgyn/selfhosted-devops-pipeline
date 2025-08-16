#!/bin/bash
rm -rf reports/dependency-check/*
find /usr/share/nginx/html/reports/ -type f -mtime +7 -delete