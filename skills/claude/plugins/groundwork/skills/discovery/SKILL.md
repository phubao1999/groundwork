---
name: discovery
description: Use this before starting any ambiguous, broad, or exploratory programming request — a vague feature ask, "help me understand this codebase/system", "what's the best way to do X", a bug report with no repro, or any task where guessing the intent risks going down the wrong path. Confirms where to look for missing context (a specific repo/file, or the web) instead of guessing or searching blindly, then reports back what was found as a plain-English mental model before any technical detail. Do NOT use for requests that are already precise and self-contained (e.g. "rename this variable in file X", "fix this exact stack trace") — Discovery exists to prevent wrong turns on unclear work, not to add ceremony to clear work.
---

# Discovery

## What this is for

Two ways an assistant can waste a user's time on an unclear request: guess at the intent and quietly run with the wrong interpretation, or overcorrect into an interrogation — a wall of unrelated multiple-choice menus ("Do you want A, B, C, or D?") for things that don't need a menu at all. Both are annoying in their own way; the first wastes time by being wrong, the second wastes time by making the user do the assistant's thinking for it.

This skill is the middle path: when you don't know where to look, ask exactly one focused question about *where to look* — not a menu of design options. Once you know where to look, go look, on your own, without narrating every step. Then hand back understanding in plain language, not a technical dump. The user should walk away from this step thinking "yes, that's what I meant" — not "here are 15 details I now have to parse."

## Step 1 — Confirm where to look, don't guess

Before reading any file, grepping any repo, or searching the web, check: do you already know where the information you need lives?

- If the user already told you (named a repo, a file, a URL, "check the docs"), skip straight to Step 2. Asking again would just be friction.
- If it's genuinely unclear — the request references something you haven't seen, or there are multiple plausible places to look and picking the wrong one would waste a round trip — ask. Keep it to one short, concrete question about the source, not a spray of hypothetical directions:

  > "To make sure I look in the right place — is the payment retry logic in the `billing-service` repo, or should I check the third-party docs for the payment provider?"

  not:

  > "I could check a) the billing repo, b) the payments repo, c) search Stack Overflow, d) look at env config, e) ask you to paste the code. Which do you want?"

The difference: the first is a targeted question that unblocks you and shows you already have a working theory. The second is delegation dressed up as a menu.

If the request is already precise enough that "where to look" is obvious (a file path was given, a stack trace names the file), don't ask anything — just proceed.

## Step 2 — Gather, quietly

Once you know where to look, do the actual work of gathering: read the code, search the web, check the docs. Don't narrate each file you open. The user doesn't need a play-by-play of the search — they need the result.

## Step 3 — Explain back: mental model first

This is the part most worth getting right. When you report back, lead with the mental model, not the details.

The mental model is the two-or-three-sentence version of "here's what this actually is and how the pieces fit together" — the thing you'd say out loud to a colleague before pulling up any code. Write it in plain language, the way you'd explain it to someone who's smart but hasn't looked at this particular system yet. No jargon dump, no wall of text, no bullet list of every file you touched.

Technical detail — specific function names, exact file paths, code snippets — is secondary. Include it only when it's genuinely needed to illustrate a point in the mental model, and even then, explain what it means in plain terms rather than pasting it and moving on. A code snippet without a plain-language explanation next to it is a technical dump, not an explanation.

A rough shape to aim for:

1. One or two sentences: what this thing fundamentally is / what problem it solves.
2. One or two sentences: how the pieces relate to each other (the mental model itself).
3. Only if it helps: a small concrete example, explained in plain language, not left to speak for itself.

Bad (technical-first, wall of text):
> The `RetryPolicy` class in `billing/retry.py` wraps `PaymentGateway.charge()` with exponential backoff (base=2, max_attempts=5, jitter=full), and `PaymentWebhookHandler` in `webhooks.py` listens for `charge.failed` events from Stripe to trigger `RetryPolicy.schedule()`, which enqueues onto the `retry_queue` Redis list with a TTL matching...

Good (mental model first):
> Retries here work like a safety net, not an immediate redo: when a charge fails, the system doesn't retry right away — it waits, and waits longer each time it fails again, up to 5 tries. The actual retrying is driven by Stripe telling us a charge failed (a webhook), not by us polling. If it's useful, the piece that decides how long to wait is `RetryPolicy` in `billing/retry.py`.

## Step 4 — Stop and wait

After presenting the mental model, stop. Don't automatically continue into deeper technical design, a plan, or code changes. The point of this step is to get confirmation that you understood the problem correctly before any further work is invested — the user might correct the mental model itself, which would make anything built on top of it wasted work. Let the user drive what happens next.

## Why this order matters

Confirming the mental model before the details works the same way as agreeing on a destination before choosing a route — if the destination is wrong, the route doesn't matter. Presenting details first (file names, functions, options) forces the user to reconstruct the big picture themselves from a pile of parts, which is slower and more error-prone than just being told the big picture directly.
