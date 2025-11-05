#!/bin/bash

# Setup script for DevOps Project
# This script initializes all submodules and prepares the project for development

echo "🚀 Setting up DevOps Project..."

# Initialize and update submodules
echo "📦 Initializing submodules..."
git submodule update --init --recursive

# Check if coffee-project has content
if [ ! -f "coffee-project/package.json" ]; then
    echo "❌ Error: coffee-project submodule not initialized properly"
    exit 1
fi

echo "✅ Setup complete!"
echo ""
echo "Project structure:"
echo "  ├── devops-project (main repo)"
echo "  └── coffee-project (submodule - ready to use)"
echo ""
echo "You can now start working on the project."
