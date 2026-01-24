#!/usr/bin/env bash
# Universal run script for LINUX Unplugged Sponsor Finder on NixOS

# Check if OPENROUTER_API_KEY is set (only needed for LLM analysis)
if [ -z "$OPENROUTER_API_KEY" ] && [ "$1" != "basic" ] && [ "$1" != "help" ]; then
    echo "⚠️  Warning: OPENROUTER_API_KEY environment variable is not set."
    echo "   Get your API key from: https://openrouter.ai/keys"
    echo "   Set it with: export OPENROUTER_API_KEY='your-key-here'"
    echo "   (Analysis will fall back to mock mode without it)"
    echo ""
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  basic          Test RSS feed parsing (no API key needed)"
    echo "  test           Test OpenRouter API connection"
    echo "  analyze [n]    Analyze n episodes with Phase 1+2 discovery (default: 3)"
    echo "  weekly         Generate comprehensive weekly report"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 basic"
    echo "  $0 test"
    echo "  $0 analyze 5"
    echo "  $0 weekly"
    echo ""
    echo "Environment variables:"
    echo "  OPENROUTER_API_KEY    Your OpenRouter API key"
}

# Main logic
case "$1" in
    "basic")
        echo "🧪 Testing basic RSS parsing..."
        exec nix-shell -p python3Packages.feedparser --run "python3 test_basic.py"
        ;;
    "test")
        echo "🔗 Testing OpenRouter API connection..."
        exec nix-shell -p python3Packages.requests --run "python3 test_openrouter.py"
        ;;
    "analyze")
        episodes="${2:-3}"
        echo "📊 Analyzing $episodes recent episodes (Phase 1 + Phase 2)..."
        exec nix-shell -p python3Packages.feedparser python3Packages.requests --run "python3 lup_sponsor_finder.py --episodes $episodes"
        ;;
    "weekly")
        echo "📈 Generating comprehensive weekly report..."
        exec nix-shell -p python3Packages.feedparser python3Packages.requests --run "python3 -c \"
import lup_sponsor_finder
analyzer = lup_sponsor_finder.LUPPodcastAnalyzer()
weekly_report = analyzer.generate_weekly_report()
print('Weekly report structure created with', len(weekly_report.top_sponsors), 'sponsors')
\""
        ;;
    "help"|"-h"|"--help"|"")
        show_usage
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
