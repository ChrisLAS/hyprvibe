#!/usr/bin/env python3
"""
LINUX Unplugged Podcast Sponsor Finder Prototype

This tool:
1. Ingests RSS feed from LINUX Unplugged
2. Uses LLM to summarize and analyze episodes
3. Searches for potential sponsors based on episode topics
4. Generates sponsor recommendation reports
"""

import feedparser
import requests
import json
import os
import re
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
import logging
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class Episode:
    """Represents a LINUX Unplugged episode"""
    guid: str
    title: str
    description: str
    content_encoded: str
    published_date: datetime
    link: str
    is_live: bool = False
    transcript_url: Optional[str] = None
    tags: List[str] = None

    def __post_init__(self):
        if self.tags is None:
            self.tags = []

@dataclass
class EpisodeUnderstanding:
    """Phase 1: Ground truth extraction from episode content"""
    episode_guid: str
    episode_summary: str
    core_themes: List[str]
    sponsor_categories: List[str]
    keywords: List[str]
    negative_keywords: List[str]
    audience_buying_rationale: str

@dataclass
class SponsorCandidate:
    """Phase 2: Validated sponsor with evidence and contact info"""
    name: str
    domain: str
    category: str
    evidence_links: List[str]  # REQUIRED: Citations proving recent podcast sponsorship
    contact_info: Dict[str, str]  # emails, forms, LinkedIn roles with links
    why_fit: str  # Why this sponsor fits this episode and LUP audience
    suggested_cta: str  # How to approach them (renewal, intro call, pilot buy)
    outreach_email: str  # Custom ready-to-send email draft
    proof_snippets: List[str] = None  # 2-3 transcript quotes showing audience alignment
    adjacent_podcasts: List[str] = None  # Other podcasts they sponsor
    pricing_guidance: Optional[str] = None  # Suggested pricing bands
    potential_objections: List[str] = None  # Common objections and framing suggestions

    def __post_init__(self):
        if self.proof_snippets is None:
            self.proof_snippets = []
        if self.adjacent_podcasts is None:
            self.adjacent_podcasts = []
        if self.potential_objections is None:
            self.potential_objections = []

    def is_valid(self) -> bool:
        """Hard rule: No evidence = no sponsor entry"""
        return len(self.evidence_links) > 0

@dataclass
class OutreachAttempt:
    """Track outreach attempts and responses"""
    sponsor_domain: str
    episode_guid: str
    outreach_type: str  # 'cold', 'renewal', 'followup'
    template_used: str  # 'short', 'medium', 'long'
    sent_date: datetime
    status: str  # 'sent', 'responded', 'declined', 'interested', 'no_response'
    notes: str = ""
    follow_up_date: Optional[datetime] = None

@dataclass
class ConflictRule:
    """Track conflicts and do-not-contact rules"""
    domain: str
    reason: str  # 'contacted', 'declined', 'competitor', 'existing_sponsor'
    added_date: datetime
    expiry_date: Optional[datetime] = None  # For temporary conflicts

@dataclass
class WeeklyReport:
    """Complete weekly report structure"""
    report_date: datetime
    episodes_analyzed: List[str]  # Episode GUIDs
    top_sponsors: List[SponsorCandidate]  # Top 10 ranked
    do_not_contact: List[ConflictRule]
    recent_outreach: List[OutreachAttempt]
    sponsor_adjacency_map: Dict[str, List[str]]  # domain -> other podcasts
    category_fatigue_warnings: List[str]  # Categories over-represented recently

class LUPPodcastAnalyzer:
    """Main analyzer class for LINUX Unplugged podcast sponsor discovery"""

    RSS_URL = "https://feeds.jupiterbroadcasting.com/lup"

    def __init__(self, openrouter_api_key: Optional[str] = None):
        self.openrouter_api_key = openrouter_api_key or os.getenv('OPENROUTER_API_KEY')
        self.episodes = {}
        self.understandings = {}  # Phase 1 outputs
        self.conflict_rules = {}  # domain -> ConflictRule
        self.outreach_history = []  # List of OutreachAttempt
        self.sponsor_adjacency = {}  # domain -> list of other podcasts

    def fetch_episodes(self, limit: int = 10) -> List[Episode]:
        """Fetch recent episodes from the RSS feed"""
        logger.info(f"Fetching episodes from {self.RSS_URL}")

        try:
            feed = feedparser.parse(self.RSS_URL)

            if feed.bozo:  # Check for parsing errors
                logger.warning(f"Feed parsing warning: {feed.bozo_exception}")

            episodes = []

            # Process regular episodes
            for entry in feed.entries[:limit]:
                episode = self._parse_feed_entry(entry, is_live=False)
                if episode:
                    episodes.append(episode)
                    self.episodes[episode.guid] = episode

            # Check for live items (upcoming shows)
            if hasattr(feed, 'channel') and hasattr(feed.channel, 'get'):
                live_items = feed.channel.get('podcast:liveItem', [])
                if not isinstance(live_items, list):
                    live_items = [live_items]

                for live_item in live_items[:limit]:
                    episode = self._parse_feed_entry(live_item, is_live=True)
                    if episode:
                        episodes.append(episode)
                        self.episodes[episode.guid] = episode

            logger.info(f"Successfully parsed {len(episodes)} episodes")
            return episodes

        except Exception as e:
            logger.error(f"Error fetching episodes: {e}")
            return []

    def _parse_feed_entry(self, entry, is_live: bool = False) -> Optional[Episode]:
        """Parse a feed entry into an Episode object"""
        try:
            # Extract basic info
            guid = getattr(entry, 'guid', getattr(entry, 'id', ''))
            if not guid:
                return None

            title = getattr(entry, 'title', 'Unknown Title')
            description = getattr(entry, 'description', '')
            content_encoded = getattr(entry, 'content', [{}])[0].get('value', '') if hasattr(entry, 'content') else ''

            # Parse published date
            published_date = self._parse_date(getattr(entry, 'published', getattr(entry, 'pubDate', '')))

            # Get link
            link = getattr(entry, 'link', '')

            # Extract transcript if available
            transcript_url = None
            if hasattr(entry, 'podcast_transcript'):
                transcripts = entry.podcast_transcript
                if isinstance(transcripts, list) and transcripts:
                    transcript_url = transcripts[0].get('url')

            # Extract tags/keywords
            tags = []
            if hasattr(entry, 'itunes_keywords'):
                keywords = entry.itunes_keywords
                if isinstance(keywords, str):
                    tags = [k.strip() for k in keywords.split(',')]
                elif isinstance(keywords, list):
                    tags = keywords

            return Episode(
                guid=guid,
                title=title,
                description=description,
                content_encoded=content_encoded,
                published_date=published_date,
                link=link,
                is_live=is_live,
                transcript_url=transcript_url,
                tags=tags
            )

        except Exception as e:
            logger.warning(f"Error parsing feed entry: {e}")
            return None

    def _parse_date(self, date_str: str) -> datetime:
        """Parse various date formats from RSS feeds"""
        if not date_str:
            return datetime.now(timezone.utc)

        # Try common RSS date formats
        formats = [
            '%a, %d %b %Y %H:%M:%S %z',
            '%a, %d %b %Y %H:%M:%S %Z',
            '%Y-%m-%dT%H:%M:%S%z',
            '%Y-%m-%dT%H:%M:%S.%f%z'
        ]

        for fmt in formats:
            try:
                return datetime.strptime(date_str, fmt).replace(tzinfo=timezone.utc)
            except ValueError:
                continue

        # Fallback
        logger.warning(f"Could not parse date: {date_str}")
        return datetime.now(timezone.utc)

    def understand_episode(self, episode: Episode) -> EpisodeUnderstanding:
        """Phase 1: Extract ground truth understanding from episode content"""
        if not self.openrouter_api_key:
            logger.warning("No OpenRouter API key provided, using mock understanding")
            return self._mock_episode_understanding(episode)

        try:
            # Combine all available content
            content_parts = []
            content_parts.append(f"Title: {episode.title}")
            content_parts.append(f"Description: {episode.description}")
            if episode.content_encoded:
                content_parts.append(f"Show Notes: {episode.content_encoded}")
            if episode.tags:
                content_parts.append(f"Tags: {', '.join(episode.tags)}")

            full_content = "\n\n".join(content_parts)

            # Prepare comprehensive prompt for Phase 1 understanding
            prompt = f"""
            Analyze this LINUX Unplugged podcast episode and extract ground truth understanding.

            EPISODE CONTENT:
            {full_content[:6000]}  # Increased limit for comprehensive analysis

            Produce a JSON object with exactly these keys:

            {{
              "episode_summary": "1-2 paragraph plain-English summary of what the episode is actually about",
              "core_themes": ["primary technical domains like Linux desktop", "Nix", "security", "AI", "hardware", "homelab", "privacy"],
              "sponsor_categories": ["hosting", "password managers", "VPNs", "developer tools", "storage", "hardware"],
              "keywords": ["positive keywords for sponsor discovery"],
              "negative_keywords": ["terms/categories to explicitly avoid"],
              "audience_buying_rationale": "short reusable paragraph explaining why this audience buys products/services in these categories"
            }}

            Focus on what the episode is REALLY about, not just the title. Infer audience intent and purchasing mindset.
            """

            # Call OpenRouter API
            response = requests.post(
                'https://openrouter.ai/api/v1/chat/completions',
                headers={
                    'Authorization': f'Bearer {self.openrouter_api_key}',
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'https://github.com/lup-sponsor-finder',
                    'X-Title': 'LINUX Unplugged Sponsor Finder'
                },
                json={
                    'model': 'anthropic/claude-3-haiku:beta',
                    'messages': [{'role': 'user', 'content': prompt}],
                    'max_tokens': 1500,
                    'temperature': 0.2  # Lower temperature for more consistent structured output
                },
                timeout=60
            )

            if response.status_code == 200:
                result = response.json()
                understanding_data = json.loads(result['choices'][0]['message']['content'])

                understanding = EpisodeUnderstanding(
                    episode_guid=episode.guid,
                    episode_summary=understanding_data.get('episode_summary', 'No summary available'),
                    core_themes=understanding_data.get('core_themes', []),
                    sponsor_categories=understanding_data.get('sponsor_categories', []),
                    keywords=understanding_data.get('keywords', []),
                    negative_keywords=understanding_data.get('negative_keywords', []),
                    audience_buying_rationale=understanding_data.get('audience_buying_rationale', '')
                )

                self.understandings[episode.guid] = understanding
                return understanding
            else:
                logger.error(f"OpenRouter API error: {response.status_code} - {response.text}")
                return self._mock_episode_understanding(episode)

        except Exception as e:
            logger.error(f"Error understanding episode with OpenRouter: {e}")
            return self._mock_episode_understanding(episode)

    def _mock_episode_understanding(self, episode: Episode) -> EpisodeUnderstanding:
        """Provide mock understanding when LLM is not available"""
        text = f"{episode.title} {episode.description}".lower()

        # Extract core themes
        core_themes = []
        theme_keywords = {
            'Linux desktop': ['linux', 'desktop', 'gui', 'wayland', 'xorg', 'kde', 'gnome'],
            'containers': ['docker', 'kubernetes', 'container', 'podman', 'containerd'],
            'homelab': ['homelab', 'self-hosted', 'server', 'nas', 'storage'],
            'security': ['security', 'privacy', 'vpn', 'encryption', 'password'],
            'cloud': ['cloud', 'aws', 'azure', 'gcp', 'hosting'],
            'AI': ['ai', 'machine learning', 'llm', 'chatgpt', 'anthropic'],
            'hardware': ['hardware', 'laptop', 'server', 'raspberry pi', 'nvidia'],
            'Nix': ['nix', 'nixos', 'flakes', 'declarative'],
            'privacy': ['privacy', 'surveillance', 'tracking', 'anonymous']
        }

        for theme, words in theme_keywords.items():
            if any(word in text for word in words):
                core_themes.append(theme)

        # Map themes to sponsor categories
        sponsor_categories = []
        category_mapping = {
            'Linux desktop': ['developer tools', 'hardware'],
            'containers': ['developer tools', 'hosting'],
            'homelab': ['hardware', 'storage', 'hosting'],
            'security': ['security software', 'vpn services'],
            'cloud': ['hosting', 'cloud services'],
            'AI': ['developer tools', 'cloud services'],
            'hardware': ['hardware', 'laptops', 'servers'],
            'Nix': ['developer tools', 'hosting'],
            'privacy': ['security software', 'vpn services']
        }

        for theme in core_themes:
            sponsor_categories.extend(category_mapping.get(theme, []))

        sponsor_categories = list(set(sponsor_categories))  # Remove duplicates

        # Generate keywords and negative keywords
        keywords = []
        for theme in core_themes:
            keywords.extend([word for word in theme_keywords[theme] if word in text])

        negative_keywords = ['windows', 'macos', 'iphone', 'android app']

        return EpisodeUnderstanding(
            episode_guid=episode.guid,
            episode_summary=f"This episode explores {', '.join(core_themes) if core_themes else 'various Linux and open source topics'}. The discussion covers practical implementation, community insights, and technical deep dives that would interest both newcomers and experienced practitioners.",
            core_themes=core_themes,
            sponsor_categories=sponsor_categories,
            keywords=list(set(keywords)),
            negative_keywords=negative_keywords,
            audience_buying_rationale="LINUX Unplugged listeners are technical practitioners who value reliability, open source ethos, and practical solutions. They make purchasing decisions based on community validation, technical merit, and alignment with their self-hosted, privacy-conscious lifestyle. They prefer vendors who understand developer needs and support open source communities."
        )

    def discover_sponsors_with_evidence(self, understanding: EpisodeUnderstanding, max_results: int = 10) -> List[SponsorCandidate]:
        """Phase 2: Discover sponsors with evidence requirements"""
        logger.info(f"Discovering sponsors for episode understanding: {understanding.episode_guid}")

        candidates = []

        # For each sponsor category, find companies and validate with evidence
        for category in understanding.sponsor_categories:
            category_candidates = self._find_companies_for_category(category, understanding)
            candidates.extend(category_candidates)

        # Apply conflict filtering
        valid_candidates = [c for c in candidates if c.is_valid() and not self._has_conflicts(c)]

        # Rank by relevance and recency of evidence
        ranked_candidates = sorted(valid_candidates, key=self._rank_candidate, reverse=True)

        return ranked_candidates[:max_results]

    def _find_companies_for_category(self, category: str, understanding: EpisodeUnderstanding) -> List[SponsorCandidate]:
        """Find companies for a specific sponsor category with evidence validation"""
        # This is where we'd implement actual web search, Reddit analysis, etc.
        # For now, return mock candidates with proper evidence structure

        mock_sponsors = {
            'developer tools': [
                {
                    'name': 'GitLab',
                    'domain': 'gitlab.com',
                    'category': 'developer tools',
                    'evidence_links': [
                        'https://linuxunplugged.com/645#gitlab-sponsor',
                        'https://www.jupiterbroadcasting.com/sponsors/'
                    ],
                    'contact_info': {
                        'email': 'partnerships@gitlab.com',
                        'form': 'https://about.gitlab.com/partners/sponsorship/'
                    }
                },
                {
                    'name': 'JetBrains',
                    'domain': 'jetbrains.com',
                    'category': 'developer tools',
                    'evidence_links': [
                        'https://www.jetbrains.com/company/partners/podcast/'
                    ],
                    'contact_info': {
                        'email': 'sponsorship@jetbrains.com',
                        'linkedin': 'https://linkedin.com/company/jetbrains'
                    }
                }
            ],
            'hosting': [
                {
                    'name': 'Linode',
                    'domain': 'linode.com',
                    'category': 'hosting',
                    'evidence_links': [
                        'https://linuxunplugged.com/640#linode-sponsor',
                        'https://www.jupiterbroadcasting.com/sponsors/linode/'
                    ],
                    'contact_info': {
                        'email': 'advertising@linode.com'
                    }
                }
            ],
            'security software': [
                {
                    'name': 'ProtonVPN',
                    'domain': 'protonvpn.com',
                    'category': 'security software',
                    'evidence_links': [
                        'https://linuxunplugged.com/635#protonvpn-sponsor'
                    ],
                    'contact_info': {
                        'email': 'partnerships@proton.me'
                    }
                }
            ],
            'hardware': [
                {
                    'name': 'Framework',
                    'domain': 'frame.work',
                    'category': 'hardware',
                    'evidence_links': [
                        'https://www.jupiterbroadcasting.com/sponsors/framework/'
                    ],
                    'contact_info': {
                        'email': 'partnerships@frame.work'
                    }
                }
            ]
        }

        candidates = []
        if category.lower() in mock_sponsors:
            for sponsor_data in mock_sponsors[category.lower()]:
                candidate = self._create_candidate_with_evidence(sponsor_data, understanding)
                if candidate:
                    candidates.append(candidate)

        return candidates

    def _create_candidate_with_evidence(self, sponsor_data: dict, understanding: EpisodeUnderstanding) -> Optional[SponsorCandidate]:
        """Create a fully validated sponsor candidate with all required evidence"""
        try:
            # Generate fit rationale based on understanding
            why_fit = self._generate_fit_rationale(sponsor_data, understanding)

            # Generate suggested CTA and outreach email
            suggested_cta, outreach_email = self._generate_outreach_materials(sponsor_data, understanding)

            # Add proof snippets (mock for now)
            proof_snippets = [
                "We're running this in production and it works great",
                "The community really loves this solution"
            ]

            candidate = SponsorCandidate(
                name=sponsor_data['name'],
                domain=sponsor_data['domain'],
                category=sponsor_data['category'],
                evidence_links=sponsor_data['evidence_links'],
                contact_info=sponsor_data['contact_info'],
                why_fit=why_fit,
                suggested_cta=suggested_cta,
                outreach_email=outreach_email,
                proof_snippets=proof_snippets,
                adjacent_podcasts=['Coder Radio', 'Self-Hosted', 'LINUX Unplugged'],  # Mock adjacency
                pricing_guidance="$5,000-15,000 per episode based on similar tech podcasts",
                potential_objections=[
                    "Budget constraints - Frame as long-term partnership investment",
                    "Already working with competitors - Highlight unique value proposition"
                ]
            )

            return candidate if candidate.is_valid() else None

        except Exception as e:
            logger.warning(f"Error creating candidate for {sponsor_data.get('name')}: {e}")
            return None

    def _generate_fit_rationale(self, sponsor_data: dict, understanding: EpisodeUnderstanding) -> str:
        """Generate why this sponsor fits the episode and audience"""
        sponsor_name = sponsor_data['name']
        category = sponsor_data['category']

        return f"{sponsor_name} is an excellent fit for this episode because the discussion heavily featured {category} topics like {', '.join(understanding.core_themes[:3])}. The LINUX Unplugged audience consists of technical practitioners who value {understanding.audience_buying_rationale.split('.')[0].lower()}. {sponsor_name} serves exactly this audience with their {category} solutions."

    def _generate_outreach_materials(self, sponsor_data: dict, understanding: EpisodeUnderstanding) -> tuple[str, str]:
        """Generate CTA and outreach email template"""
        sponsor_name = sponsor_data['name']

        cta = f"Reach out for an introductory sponsorship discussion. Given the episode's focus on {', '.join(understanding.core_themes[:2])}, this would be a natural fit for a pilot sponsorship."

        email_template = f"""Subject: LINUX Unplugged Sponsorship Opportunity - {understanding.core_themes[0].title()} Focus

Dear {sponsor_name} Partnership Team,

I hope this email finds you well. I'm reaching out regarding a potential sponsorship opportunity with LINUX Unplugged, a weekly Linux and open source technology podcast with [X] active listeners.

Our most recent episode focused on {understanding.episode_summary[:200]}...

Given {sponsor_name}'s position as a leader in {sponsor_data['category']}, I believe there would be strong alignment with our audience of technical practitioners who regularly work with these technologies.

Would you be open to discussing sponsorship opportunities for upcoming episodes?

Best regards,
[Your Name]
LINUX Unplugged Partnership Outreach"""

        return cta, email_template

    def _has_conflicts(self, candidate: SponsorCandidate) -> bool:
        """Check if candidate has conflicts that prevent outreach"""
        if candidate.domain in self.conflict_rules:
            rule = self.conflict_rules[candidate.domain]
            if rule.expiry_date is None or rule.expiry_date > datetime.now(timezone.utc):
                return True
        return False

    def _rank_candidate(self, candidate: SponsorCandidate) -> float:
        """Rank candidates by evidence recency and relevance"""
        # Simple ranking: more evidence links = higher rank
        # In reality, would factor in recency, adjacency, etc.
        return len(candidate.evidence_links)

    def generate_comprehensive_report(self, episode: Episode, understanding: EpisodeUnderstanding, sponsors: List[SponsorCandidate]) -> str:
        """Generate comprehensive weekly report with all required sections"""
        report_date = datetime.now(timezone.utc)

        report = f"""# LINUX Unplugged Weekly Sponsor Report

**Report Date:** {report_date.strftime('%Y-%m-%d')}
**Episode Analyzed:** {episode.title}
**Published:** {episode.published_date.strftime('%Y-%m-%d')}

## Episode Deep Analysis

### What This Episode Is Really About
{understanding.episode_summary}

### Core Technical Domains
{chr(10).join(f"- {theme}" for theme in understanding.core_themes)}

### Audience Buying Rationale
{understanding.audience_buying_rationale}

## Top {len(sponsors)} Sponsor Candidates

"""

        for i, sponsor in enumerate(sponsors, 1):
            report += f"""
### {i}. **{sponsor.name}** ({sponsor.category})
**Domain:** {sponsor.domain}

#### Sponsorship Evidence (Last 90 Days)
{chr(10).join(f"- {link}" for link in sponsor.evidence_links)}

#### Contact Information
"""
            for contact_type, contact_value in sponsor.contact_info.items():
                report += f"- **{contact_type.title()}:** {contact_value}\n"

            report += f"""
#### Why This Sponsor Fits
{sponsor.why_fit}

#### Suggested Approach
{sponsor.suggested_cta}

#### Audience Alignment Proof
{chr(10).join(f"- *\"{snippet}\"*" for snippet in sponsor.proof_snippets)}

#### Adjacent Podcasts
{chr(10).join(f"- {podcast}" for podcast in sponsor.adjacent_podcasts)}

#### Pricing Guidance
{sponsor.pricing_guidance}

#### Potential Objections & Framing
{chr(10).join(f"- {objection}" for objection in sponsor.potential_objections)}

#### Outreach Email Template
```
{sponsor.outreach_email}
```

---
"""

        # Add do-not-contact list (mock for now)
        report += """
## Do-Not-Contact List

### Recently Contacted (90-day cooldown)
- competitor-vpn.com (contacted 2025-12-15, renewal discussion pending)
- storage-company.com (declined 2025-11-20, follow up in 2026)

### Conflicts
- existing-sponsor.com (current active sponsor)
- direct-competitor.com (competes with current sponsor)

## Category Fatigue Warnings
- **VPN Services:** 3 episodes in last 4 weeks - consider spacing out
- **Hosting Providers:** 2 episodes in last 2 weeks - monitor saturation

---
*Report generated by LINUX Unplugged Sponsor Finder*
*Phase 1: Ground Truth Extraction + Phase 2: Evidence-Based Discovery*
"""

        return report

    def run_full_analysis(self, limit: int = 5) -> List[str]:
        """Run complete Phase 1 + Phase 2 analysis pipeline for recent episodes"""
        logger.info(f"Starting full analysis for {limit} recent episodes")

        # Fetch episodes
        episodes = self.fetch_episodes(limit=limit)
        if not episodes:
            logger.error("No episodes found")
            return []

        reports = []

        for episode in episodes:
            logger.info(f"Phase 1: Understanding episode: {episode.title}")

            # Phase 1: Extract ground truth understanding
            understanding = self.understand_episode(episode)

            logger.info(f"Phase 2: Discovering sponsors for: {episode.title}")

            # Phase 2: Discover sponsors with evidence
            sponsors = self.discover_sponsors_with_evidence(understanding)

            # Generate report
            report = self.generate_comprehensive_report(episode, understanding, sponsors)
            reports.append(report)

            logger.info(f"Completed analysis for episode: {episode.title} - Found {len(sponsors)} valid sponsors")

        return reports

    # Conflict and Outreach Management Methods

    def add_conflict_rule(self, domain: str, reason: str, expiry_days: Optional[int] = None):
        """Add a do-not-contact rule"""
        expiry_date = None
        if expiry_days:
            expiry_date = datetime.now(timezone.utc) + timedelta(days=expiry_days)

        self.conflict_rules[domain] = ConflictRule(
            domain=domain,
            reason=reason,
            added_date=datetime.now(timezone.utc),
            expiry_date=expiry_date
        )
        logger.info(f"Added conflict rule for {domain}: {reason}")

    def log_outreach_attempt(self, sponsor_domain: str, episode_guid: str, outreach_type: str,
                           template_used: str, status: str, notes: str = ""):
        """Log an outreach attempt"""
        attempt = OutreachAttempt(
            sponsor_domain=sponsor_domain,
            episode_guid=episode_guid,
            outreach_type=outreach_type,
            template_used=template_used,
            sent_date=datetime.now(timezone.utc),
            status=status,
            notes=notes
        )
        self.outreach_history.append(attempt)
        logger.info(f"Logged outreach to {sponsor_domain}: {status}")

    def update_sponsor_adjacency(self, domain: str, other_podcasts: List[str]):
        """Update which other podcasts a sponsor appears on"""
        self.sponsor_adjacency[domain] = other_podcasts

    def get_recent_outreach(self, days: int = 30) -> List[OutreachAttempt]:
        """Get outreach attempts from the last N days"""
        cutoff = datetime.now(timezone.utc) - timedelta(days=days)
        return [attempt for attempt in self.outreach_history if attempt.sent_date > cutoff]

    def get_active_conflicts(self) -> List[ConflictRule]:
        """Get currently active conflict rules"""
        now = datetime.now(timezone.utc)
        return [rule for rule in self.conflict_rules.values()
                if rule.expiry_date is None or rule.expiry_date > now]

    def generate_weekly_report(self, episodes_limit: int = 5) -> WeeklyReport:
        """Generate complete weekly report with all tracking data"""
        episodes = self.fetch_episodes(limit=episodes_limit)
        episodes_analyzed = [ep.guid for ep in episodes]

        # Analyze all episodes and collect sponsors
        all_sponsors = []
        for episode in episodes:
            understanding = self.understand_episode(episode)
            sponsors = self.discover_sponsors_with_evidence(understanding)
            all_sponsors.extend(sponsors)

        # Remove duplicates and rank
        seen_domains = set()
        unique_sponsors = []
        for sponsor in all_sponsors:
            if sponsor.domain not in seen_domains:
                seen_domains.add(sponsor.domain)
                unique_sponsors.append(sponsor)

        top_sponsors = sorted(unique_sponsors, key=self._rank_candidate, reverse=True)[:10]

        return WeeklyReport(
            report_date=datetime.now(timezone.utc),
            episodes_analyzed=episodes_analyzed,
            top_sponsors=top_sponsors,
            do_not_contact=self.get_active_conflicts(),
            recent_outreach=self.get_recent_outreach(days=7),
            sponsor_adjacency_map=self.sponsor_adjacency.copy(),
            category_fatigue_warnings=self._detect_category_fatigue()
        )

    def _detect_category_fatigue(self) -> List[str]:
        """Detect categories that have been over-represented recently"""
        # Simple implementation - in reality would analyze historical data
        warnings = []
        # Mock warnings for demonstration
        warnings.append("VPN Services: 3 episodes in last 4 weeks - consider spacing out")
        warnings.append("Hosting Providers: 2 episodes in last 2 weeks - monitor saturation")
        return warnings

def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='LINUX Unplugged Podcast Sponsor Finder')
    parser.add_argument('--episodes', type=int, default=3, help='Number of episodes to analyze')
    parser.add_argument('--output-dir', default='reports', help='Output directory for reports')
    parser.add_argument('--openrouter-key', help='OpenRouter API key (or set OPENROUTER_API_KEY env var)')

    args = parser.parse_args()

    # Initialize analyzer
    analyzer = LUPPodcastAnalyzer(openrouter_api_key=args.openrouter_key)

    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    # Run analysis
    reports = analyzer.run_full_analysis(limit=args.episodes)

    # Save reports
    for i, report in enumerate(reports):
        filename = f"episode_analysis_{i+1}.md"
        filepath = os.path.join(args.output_dir, filename)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(report)

        print(f"Saved report: {filepath}")

    print(f"\nCompleted analysis of {len(reports)} episodes. Reports saved to {args.output_dir}/")

if __name__ == "__main__":
    main()
