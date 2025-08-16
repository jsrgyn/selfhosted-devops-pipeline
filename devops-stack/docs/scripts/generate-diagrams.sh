#!/bin/bash
# Gera diagramas PNG a partir de arquivos PlantUML

apt-get update && apt-get install -y plantuml || brew install plantuml

cd docs/architecture/diagrams
for file in *.puml; do
  plantuml "$file"
done