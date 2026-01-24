# LINUX Unplugged Podcast Sponsor Finder

A comprehensive tool that analyzes LINUX Unplugged podcast episodes and discovers potential sponsors through a two-phase process: Ground Truth Extraction and Evidence-Based Discovery.

## Features

### Phase 1: Episode Understanding (Ground Truth Extraction)
- **Deep Content Analysis**: Extract what episodes are *really* about beyond titles
- **Audience Intent Inference**: Understand listener motivations and purchasing mindset
- **Structured JSON Output**: episode_summary, core_themes, sponsor_categories, keywords, negative_keywords, audience_buying_rationale

### Phase 2: Sponsor Discovery with Evidence Requirements
- **Evidence-Based Validation**: Only sponsors with recent (90-day) podcast sponsorship proof
- **Contact Intelligence**: partnerships@ emails, media kits, sponsorship inquiry forms, LinkedIn roles
- **Conflict Detection**: Automatic filtering of existing sponsors, competitors, recently contacted companies
- **Outreach Materials**: Ready-to-send email templates, suggested CTAs, objection handling

### Comprehensive Reporting & Tracking
- **Weekly Reports**: Top 10 ranked sponsors with full evidence, contact info, and outreach templates
- **Do-Not-Contact Management**: Track contacted, declined, and conflicting companies
- **Outreach Tracking**: Log attempts, responses, follow-ups, and outcomes
- **Category Fatigue Detection**: Avoid over-saturation of sponsor categories
- **Sponsor Adjacency Mapping**: Track which other podcasts sponsors appear on

## Setup

**For NixOS (recommended):**
Just use the provided `run.sh` script - it handles all dependencies automatically.

**For other systems:**
```bash
pip install -r requirements.txt
```

2. **Configure API keys**:
   - Get an OpenRouter API key from https://openrouter.ai/keys
   - Set the `OPENROUTER_API_KEY` environment variable:
   ```bash
   export OPENROUTER_API_KEY="your-api-key-here"
   ```
   *(Optional - analysis falls back to mock mode without it)*

3. **Test and run the system**:
   ```bash
   # Test basic RSS parsing (no API key needed)
   ./run.sh basic

   # Test OpenRouter API connection (requires API key)
   ./run.sh test

   # Analyze episodes with Phase 1+2 discovery
   ./run.sh analyze 3

   # Generate comprehensive weekly report
   ./run.sh weekly
   ```

4. **Management Commands** (available via Python API):
   ```python
   analyzer.add_conflict_rule("example.com", "contacted", expiry_days=90)
   analyzer.log_outreach_attempt("sponsor.com", episode_guid, "cold", "medium", "sent")
   analyzer.update_sponsor_adjacency("sponsor.com", ["Coder Radio", "Self-Hosted"])
   ```

## Usage

### Command Line Options

```bash
python lup_sponsor_finder.py [options]

Options:
  --episodes INT     Number of recent episodes to analyze (default: 3)
  --output-dir DIR   Directory to save reports (default: reports)
  --openai-key KEY   OpenAI API key (or set OPENAI_API_KEY env var)
  --help            Show help message
```

### Environment Variables

- `OPENROUTER_API_KEY`: Your OpenRouter API key for episode analysis
- `SERPAPI_KEY`: (Future) Search API key for web searches
- `REDDIT_CLIENT_ID`: (Future) Reddit API client ID
- `REDDIT_CLIENT_SECRET`: (Future) Reddit API client secret
- `TWITTER_BEARER_TOKEN`: (Future) Twitter API bearer token

## Example Output

See `reports/sample_report.md` for a complete example. The tool generates markdown reports like this:

```markdown
# LINUX Unplugged Episode Analysis & Sponsor Recommendations

## Episode: Packet Sniffing Among Friends

**Published:** 2026-01-04
**Link:** https://linuxunplugged.com/...

### Episode Summary
This live episode explores network monitoring tools and home automation integration...

### Key Topics
- Network monitoring
- Home Assistant
- MQTT
- Packet analysis

### Recommended Sponsor Categories
- Dev Tools
- IoT Hardware
- Cloud Services
- Security Software

## Potential Sponsors

### 1. Tailscale
- **Domain:** tailscale.com
- **Category:** Security Software
- **Description:** Zero-trust networking
- **Fit Score:** 0.85
```

## Architecture

### Core Components

- **`LUPPodcastAnalyzer`**: Main analysis class
  - `fetch_episodes()`: Downloads and parses RSS feed
  - `analyze_episode_with_llm()`: Uses GPT to understand episode content
  - `find_potential_sponsors()`: Discovers sponsor candidates (currently stubbed)
  - `generate_report()`: Creates formatted markdown reports

### Data Models

- **`Episode`**: Podcast episode metadata
- **`EpisodeAnalysis`**: LLM-generated insights about episodes
- **`SponsorCandidate`**: Potential sponsor information

## Future Enhancements

The current prototype includes stubbed sponsor search. Future versions will add:

- **Web Search Integration**: Use SerpAPI or similar to find companies online
- **Reddit Analysis**: Scan relevant subreddits for community-favorite tools
- **X (Twitter) Monitoring**: Find companies active in Linux/tech communities
- **Company Profiling**: Extract contact info, partnership pages, and sponsorship history
- **Scoring Algorithm**: Rate sponsor fit based on multiple factors
- **Automated Outreach**: Generate personalized email drafts
- **Historical Analysis**: Track topic trends across episodes

## Dependencies

- `feedparser`: RSS/Atom feed parsing
- `requests`: HTTP client for API calls and OpenRouter integration
- `python-dateutil`: Date parsing utilities

## License

This is a prototype tool for personal use. Check the Jupiter Broadcasting terms of service for any commercial applications.
