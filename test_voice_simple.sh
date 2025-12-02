#!/bin/bash
# Simple voice style tester - shows usage and examples

if [ "$1" = "list" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "OpenVoice Style Tester (curl version)"
    echo "======================================"
    echo ""
    echo "Usage:"
    echo "  ./test_voice_curl.sh [style] [text]"
    echo ""
    echo "Available styles:"
    echo "  • default"
    echo "  • excited"
    echo "  • friendly"
    echo "  • cheerful"
    echo "  • sad"
    echo "  • angry"
    echo "  • terrified"
    echo "  • shouting"
    echo "  • whispering"
    echo ""
    echo "Examples:"
    echo "  ./test_voice_curl.sh"
    echo "  ./test_voice_curl.sh excited"
    echo "  ./test_voice_curl.sh cheerful 'Hello! This is cheerful!'"
    echo ""
    echo "Test all styles:"
    echo "  for style in default excited friendly cheerful sad angry terrified shouting whispering; do"
    echo "    ./test_voice_curl.sh \$style 'Hello Seedling!'"
    echo "    sleep 1"
    echo "  done"
    exit 0
fi

# Run the curl test script
exec ./test_voice_curl.sh "$@"

