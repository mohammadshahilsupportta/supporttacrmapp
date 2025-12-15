#!/bin/bash

# Script to analyze the website repository and identify changes
# Usage: ./analyze_website.sh

WEBSITE_DIR="../supporttacrmweb"
FLUTTER_DIR="."

echo "🔍 Analyzing Website Repository..."
echo ""

if [ ! -d "$WEBSITE_DIR" ]; then
    echo "❌ Website directory not found: $WEBSITE_DIR"
    echo "Please clone the repository first:"
    echo "  cd /home/shahil/Desktop/Flutter_Supportta"
    echo "  git clone git@github.com:supportta-projects/supporttacrmweb.git supporttacrmweb"
    exit 1
fi

echo "✅ Website directory found"
echo ""

# 1. Check framework
echo "📦 Framework Detection:"
if [ -f "$WEBSITE_DIR/package.json" ]; then
    echo "  - Found package.json"
    grep -E '"next"|"react"|"vue"|"angular"' "$WEBSITE_DIR/package.json" | head -3
fi
echo ""

# 2. Find all pages/routes
echo "📄 Pages/Routes:"
if [ -d "$WEBSITE_DIR/app" ]; then
    find "$WEBSITE_DIR/app" -name "page.tsx" -o -name "page.ts" -o -name "index.tsx" | head -20
elif [ -d "$WEBSITE_DIR/pages" ]; then
    find "$WEBSITE_DIR/pages" -name "*.tsx" -o -name "*.ts" | head -20
elif [ -d "$WEBSITE_DIR/src/pages" ]; then
    find "$WEBSITE_DIR/src/pages" -name "*.tsx" -o -name "*.ts" | head -20
fi
echo ""

# 3. Find Supabase usage
echo "🗄️  Supabase Usage:"
grep -r "supabase" "$WEBSITE_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" | grep -v node_modules | head -10
echo ""

# 4. Find API routes
echo "🔌 API Routes:"
find "$WEBSITE_DIR" -path "*/api/*" -name "*.ts" -o -path "*/api/*" -name "*.tsx" | head -10
echo ""

# 5. Find data models/types
echo "📊 Data Models/Types:"
find "$WEBSITE_DIR" -name "*.ts" -o -name "*.tsx" | xargs grep -l "interface\|type\|enum" | grep -v node_modules | head -10
echo ""

# 6. Find components
echo "🧩 Components:"
find "$WEBSITE_DIR" -path "*/components/*" -name "*.tsx" -o -path "*/components/*" -name "*.ts" | head -20
echo ""

# 7. Check state management
echo "🔄 State Management:"
grep -r "zustand\|redux\|context\|recoil" "$WEBSITE_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" | grep -v node_modules | head -5
echo ""

# 8. Find authentication logic
echo "🔐 Authentication:"
grep -r "signIn\|signUp\|auth\|login" "$WEBSITE_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" | grep -v node_modules | head -10
echo ""

echo "✅ Analysis complete!"
echo ""
echo "Next steps:"
echo "1. Review the output above"
echo "2. Compare with current Flutter implementation"
echo "3. Update Flutter app to match website changes"

