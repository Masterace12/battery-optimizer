#!/bin/bash
# List all files created for the Steam Deck Power Manager project

echo "Steam Deck Power Manager - Project Files"
echo "========================================"
echo ""

echo "Main application files:"
find steamdeck_power_manager -type f | sort
echo ""

echo "Installation files:"
ls -1 install.sh uninstall.sh 2>/dev/null || echo "Installation scripts not found"
echo ""

echo "Service files:"
ls -1 steamdeck_power_manager/service/*.service 2>/dev/null || echo "Service files not found"
echo ""

echo "Configuration files:"
ls -1 steamdeck_power_manager/config/*.json 2>/dev/null || echo "Configuration files not found"
echo ""

echo "Documentation:"
ls -1 README.md LICENSE PROJECT_SUMMARY.md 2>/dev/null || echo "Documentation files not found"
echo ""

echo "Test scripts:"
ls -1 *_test.py test.py 2>/dev/null || echo "Test scripts not found"
echo ""

echo "Packaging files:"
ls -1 *.json *.sh 2>/dev/null | grep -v install.sh | grep -v uninstall.sh || echo "Packaging files not found"
echo ""