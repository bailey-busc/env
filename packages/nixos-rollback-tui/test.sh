#!/usr/bin/env bash

# Test script for nixos-rollback-tui
# This script tests the basic functionality without requiring a full build

set -euo pipefail

echo "🧪 Testing NixOS Rollback TUI"
echo "=============================="

# Check if we're on NixOS
if [[ ! -f /etc/nixos/configuration.nix ]]; then
    echo "⚠️  Warning: Not running on NixOS, some tests may fail"
fi

# Test 1: Check if required commands exist
echo "📋 Checking required commands..."

commands=("nixos-rebuild" "nix-env")
for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo "✅ $cmd found"
    else
        echo "❌ $cmd not found"
    fi
done

# Test 2: Test generation listing commands
echo ""
echo "📋 Testing generation listing..."

echo "System generations:"
if nixos-rebuild list-generations 2>/dev/null | head -5; then
    echo "✅ System generation listing works"
else
    echo "❌ System generation listing failed"
fi

echo ""
echo "User generations:"
if nix-env --list-generations 2>/dev/null | head -5; then
    echo "✅ User generation listing works"
else
    echo "❌ User generation listing failed"
fi

# Test 3: Check Rust/Cargo availability
echo ""
echo "📋 Checking Rust toolchain..."

if command -v cargo &> /dev/null; then
    echo "✅ Cargo found"
    echo "Cargo version: $(cargo --version)"
    
    # Test compilation
    echo "🔨 Testing compilation..."
    cd "$(dirname "$0")"
    if cargo check --quiet 2>/dev/null; then
        echo "✅ Code compiles successfully"
    else
        echo "❌ Compilation failed"
        echo "Try running: nix shell nixpkgs#cargo nixpkgs#rustc -c cargo check"
    fi
else
    echo "❌ Cargo not found"
    echo "To test compilation, run: nix shell nixpkgs#cargo nixpkgs#rustc -c ./test.sh"
fi

# Test 4: Check dependencies
echo ""
echo "📋 Checking dependencies..."

deps=("sudo" "grep" "awk" "date")
for dep in "${deps[@]}"; do
    if command -v "$dep" &> /dev/null; then
        echo "✅ $dep found"
    else
        echo "❌ $dep not found"
    fi
done

echo ""
echo "🎉 Test complete!"
echo ""
echo "To build and run the application:"
echo "  nix build .#nixos-rollback-tui"
echo "  ./result/bin/nixos-rollback-tui --help"
echo ""
echo "Or run directly with Nix:"
echo "  nix run .#nixos-rollback-tui -- --help"