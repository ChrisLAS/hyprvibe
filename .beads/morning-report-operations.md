# Morning Report Operations

## Audience
Lore, operating on rvbee/OpenClaw.

## Purpose
Document the March 12, 2026 morning report failure, the corrective work that was applied, and the rules for safely editing and operating the morning report going forward.

## Incident Summary
- Date: 2026-03-12
- User-visible failures:
  - The morning report included fabricated calendar events that were not on Chris's Google Calendar.
  - Two different versions of the morning report appeared with different formatting and slightly different detail.

## Root Cause

### 1. Wrong calendar data was not from Google Calendar
The report generator itself was reading the correct Google Calendar ICS feed:
- `~/.openclaw/scripts/unified_morning_report.py`
- calendar source path: `~/.openclaw/credentials/google/calendar_ics_url.txt`

The actual script output for 2026-03-12 contained the real event:
- `Nick x Chris - Weekly Call`

The bad entries:
- `Team Standup Meeting (Zoom)`
- `Lunch with Sarah at Good Eats`
- `Project Deadline - Submit Draft Report`
- `Gym Workout Session`

were introduced after script execution by the cron-run LLM session. The model was told to return stdout verbatim, but it did not comply and instead rewrote the report.

This means:
- the calendar integration was not the source of corruption
- the LLM relay layer was the source of corruption

### 2. The duplicate report came from a second manual send
After the scheduled run posted the bad version, Lore investigated live in the same Telegram topic and manually ran the morning report script again. During that investigation, Lore explicitly sent another report version to the same thread.

So the two versions came from:
- scheduled cron report
- manual follow-up send during investigation

This was not caused by the Python report generator itself.

## Corrective Work Applied

### New deterministic delivery wrapper
Added:
- `~/.openclaw/scripts/deliver_morning_report.py`

This wrapper now owns:
- running `unified_morning_report.py`
- validating the output is not obviously broken
- sending the exact stdout to Telegram topic 6
- logging the generated report under `/tmp/openclaw-morning-report/`

Important design choice:
- The generator remains editable by agents.
- Delivery is no longer delegated to an LLM.

### Cron job changed to stop posting model output
Updated:
- `~/.openclaw/cron/jobs.json`

The morning report cron job now:
- runs `deliver_morning_report.py`
- tells the model to execute exactly one command
- uses `delivery.mode = "none"`

Why this matters:
- even if the cron model later says something incorrect, its output is not posted to Telegram
- only the wrapper script can deliver the report

## Current Architecture

### Content generation
- File: `~/.openclaw/scripts/unified_morning_report.py`
- Responsibility: build the report text only

### Deterministic delivery
- File: `~/.openclaw/scripts/deliver_morning_report.py`
- Responsibility:
  - run generator
  - validate output
  - send exact stdout to Telegram
  - log the result

### Scheduling
- File: `~/.openclaw/cron/jobs.json`
- Job: `daily-calendar-digest-auto`
- Responsibility: invoke the wrapper, not compose or relay the report itself

## Rules For Future Agents

### Safe rule: edit the generator, not the delivery path
If the goal is to improve report content:
- edit `~/.openclaw/scripts/unified_morning_report.py`
- do not change delivery behavior unless the delivery target or transport truly needs to change

### Do not use `message.send` manually for the scheduled morning report
Unless Chris explicitly asks for a manual resend:
- do not manually post the report to Telegram topic 6
- do not “helpfully” send a second copy during debugging

Reason:
- this was one of the direct causes of the duplicate report incident

### Do not ask an LLM to rephrase or relay report stdout
Never restore a prompt pattern like:
- “run the script and reply with stdout verbatim”
- “deliver the report text yourself”

Reason:
- that pattern already failed in production
- even when the generator is correct, the LLM can hallucinate or rewrite the report

### Treat the wrapper as the delivery boundary
The wrapper should remain the only component allowed to publish the scheduled morning report.

If you need to change:
- target chat
- topic/thread id
- account/bot token selection

prefer changing:
- wrapper arguments or constants
- cron invocation arguments

instead of moving delivery back into agent reasoning

## Required Workflow For Future Morning Report Changes

### For content changes
1. Edit `~/.openclaw/scripts/unified_morning_report.py`
2. Run:
   - `python3 ~/.openclaw/scripts/deliver_morning_report.py --dry-run`
3. Confirm:
   - output validates successfully
   - a log file appears under `/tmp/openclaw-morning-report/`
4. Review the generated text in the log before allowing the next scheduled run

### For delivery changes
Only edit `~/.openclaw/scripts/deliver_morning_report.py` if one of these is true:
- Telegram target changed
- account selection changed
- validation rules need tuning
- chunking or send mechanics need improvement

After delivery changes:
1. run `--dry-run`
2. if needed, run a controlled manual send only with operator intent
3. do not also use `message.send` separately

## Validation Expectations

The wrapper currently performs lightweight validation. That is intentional.

Goal:
- catch obviously broken output
- avoid over-constraining future report evolution

Current validation is intentionally loose:
- output must not be trivially short
- output must include a calendar section

This allows future agents to:
- add sections
- reorder sections
- improve formatting

without rewriting the delivery layer every time.

## Remaining Caveat
The cron scheduler still uses an `agentTurn` to invoke the wrapper command. That means there is still some residual model risk in the command-execution step itself.

What is fixed:
- bad model output is no longer delivered as the morning report

What is not fully removed:
- a model could still fail to execute the wrapper correctly, causing a missed run

If maximum reliability is needed in the future:
- move the morning report trigger from OpenClaw cron to a direct systemd timer or shell cron entry that runs `deliver_morning_report.py` with no LLM in the path

## Operational Guidance For Lore

When Chris reports a bad morning report:
1. Check the generated log under `/tmp/openclaw-morning-report/`
2. Run:
   - `python3 ~/.openclaw/scripts/deliver_morning_report.py --dry-run`
3. Compare:
   - dry-run output
   - wrapper log
   - cron session transcript
4. Determine whether the failure came from:
   - generator content
   - wrapper delivery
   - manual resend by an agent
   - cron execution failure

Do not send a replacement report during investigation unless Chris asks for one.

## Files To Know
- `~/.openclaw/scripts/unified_morning_report.py`
- `~/.openclaw/scripts/deliver_morning_report.py`
- `~/.openclaw/cron/jobs.json`
- `~/.openclaw/credentials/google/calendar_ics_url.txt`
- `/tmp/openclaw-morning-report/`

## Final Policy
For the scheduled morning report:
- agents may evolve the generator
- agents may inspect logs
- agents may test with `--dry-run`
- agents must not sit in the content delivery path

That boundary is now intentional and should be preserved.
