---
name: ste-writing
description: Rewrite prose (docs, READMEs, PR descriptions, error messages, release notes, comments — never code) into ASD-STE100 Simplified Technical English to remove "AI slop". Use when asked to make writing not sound like AI, make docs clear or plain, enforce a controlled writing style, or write technical documentation that reads human. Two modes — strict (procedures/safety) and STE-flavored (general prose). Load proactively — without being asked — when writing or editing more than a paragraph of prose destined for a README, docs, PR description, commit message body, release notes, or error/log messages. Not needed for code, conversational answers, single-sentence edits, or implementation plans created in plan mode.
---

# ste-writing

Write prose in ASD-STE100 Simplified Technical English. This applies to documentation, READMEs, pull-request text, error messages, release notes, and comments. It does not apply to code, identifiers, or command syntax. It is not for marketing copy, essays, or anything that needs a voice — STE strips voice on purpose.

## Rules

WORDS
- Use one name for one thing. Do not call the same item by two different names.
- Use the short common word: start (not begin/commence/initiate), use (not utilize/leverage), help (not facilitate), make sure (not ensure), before (not prior to), after (not subsequent to), about (not regarding/concerning), get (not obtain/acquire), show (not demonstrate), also (not additionally/furthermore/moreover).
- Give each word one meaning. "fall" means to move down, not to decrease.
- No marketing adjectives: seamless, robust, powerful, cutting-edge, effortless, world-class, next-generation, revolutionary.
- American spelling.

VERBS
- Active voice. "the parser reads the file", not "the file is read by the parser".
- Use a verb for an action. "analyze the log", not "perform an analysis of the log".
- No stacked auxiliaries. Not "it is important to note that this may help to improve". Write "this improves X".
- No "-ing" main verb where a simple tense works.

SENTENCES
- One instruction per sentence. Max 20 words (instruction), max 25 (descriptive).
- No contractions. Use articles: a, an, the, this, these.

PUNCTUATION
- No semicolons. Write two sentences. (Note: the em dash is not banned by STE, only the semicolon is — add "no em dash" yourself if you want it gone.)

STRUCTURE
- One topic per paragraph, max six sentences. For steps, use a numbered vertical list, one action per item, imperative form. Put a condition before its command.

Write only the requested text. No preamble, no summary, no closing remarks.

## Modes

- **strict** — procedures, runbooks, safety text, error messages: apply every rule and both length caps.
- **STE-flavored** — general prose (READMEs, PR descriptions, docs): apply the sentence, paragraph, active-voice, and no-phrasal-verb discipline; relax the ~900-word dictionary lockdown so the text keeps enough range to read naturally.

## Self-lint (run before returning text)

1. Any sentence over 20 words? Split it.
2. Any semicolon? Replace with a period.
3. Any contraction? Expand it.
4. Any passive voice with a known actor? Make it active.
5. Any "-ing" main verb, nominalization ("perform an analysis"), or phrasal verb ("spin up")? Replace with a plain verb.
6. Same thing named two ways? Pick one name.

The mechanical rules above are lintable and are what removes slop. Full STE also needs human judgment (the right technical noun, whether a sentence "makes good sense") — a checker cannot certify that, and slop is not about that. This skill fixes the FORM of slop. It cannot make a hollow paragraph true.

## References (load on demand)

- **rules.md** — all 61 rules of the standard (Part 1) plus the 8 General Recommendations, distilled. Load for strict mode, or when a rule above needs its exact wording, limits, or exceptions.
- **dictionary-curated.md** — word-replacement rules for software/general prose (~1,000 entries), plus the 208 approved verbs and the recurring-errors list. Load when checking word choice.
- **dictionary-full.md** — the complete ~2,200-entry dictionary mapping. Load only when a word is not in the curated file.

Official standard, that the references are distilled from: https://www.asd-ste100.org
