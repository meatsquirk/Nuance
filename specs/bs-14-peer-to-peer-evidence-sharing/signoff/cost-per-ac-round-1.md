### Cost per AC

Tokens from the *Token usage* ledger (26 sessions, 187,581,598 tokens); cost at API list rates as of 2026-09-25 (USD per million tokens; cache writes at 1.25× input for 5-minute and 2× for 1-hour entries). Feature total **$168.05**: input $0.01, cache write $44.61, cache read $90.64, output $32.78. 26 of 26 sessions priced from their transcripts.

**Fully loaded** (direct, plus an even 1/12 share of all shared work; sums to the feature total):

| AC | Direct phases | Input | Cache write | Cache read | Output | Total tokens | Cost |
|---|---|---:|---:|---:|---:|---:|---:|
| AC-1 | CORE-3 | 311 | 561,298 | 25,488,315 | 164,995 | **26,214,919** | **$21.95** |
| AC-2 | CORE-4 | 323 | 521,823 | 22,040,581 | 146,075 | **22,708,802** | **$19.32** |
| AC-3 | RECORD-2 | 208 | 335,449 | 13,600,531 | 100,955 | **14,037,143** | **$12.38** |
| AC-4 | RECORD-2 | 208 | 335,449 | 13,600,531 | 100,955 | **14,037,143** | **$12.38** |
| AC-5 | RECORD-3 | 239 | 363,768 | 13,217,284 | 91,624 | **13,672,915** | **$12.18** |
| AC-6 | EXCHANGE-2 | 257 | 474,212 | 16,407,321 | 116,105 | **16,997,895** | **$15.32** |
| AC-7 | EXCHANGE-3 | 225 | 419,653 | 12,671,001 | 98,671 | **13,189,550** | **$12.50** |
| AC-8 | MERGE-3 | 178 | 320,741 | 10,622,125 | 88,111 | **11,031,155** | **$10.41** |
| AC-9 | MERGE-4 | 231 | 459,428 | 14,394,418 | 111,897 | **14,965,974** | **$14.05** |
| AC-10 | MERGE-2 | 247 | 397,232 | 13,687,331 | 94,201 | **14,179,011** | **$12.74** |
| AC-11 | MERGE-3 | 178 | 320,741 | 10,622,125 | 88,111 | **11,031,155** | **$10.41** |
| AC-12 | MERGE-5 | 245 | 472,182 | 14,934,006 | 109,500 | **15,515,933** | **$14.40** |
| **Total** |  | 2,850 | 4,981,974 | 181,285,570 | 1,311,204 | **187,581,598** | **$168.05** |

**Direct** (behavior phases only, each split evenly across the ACs its *Target AC* names):

| AC | Phases | Input | Cache write | Cache read | Output | Total tokens | Cost |
|---|---|---:|---:|---:|---:|---:|---:|
| AC-1 | CORE-3 | 190 | 355,826 | 17,868,569 | 101,541 | **18,326,126** | **$14.66** |
| AC-2 | CORE-4 | 202 | 316,351 | 14,420,835 | 82,621 | **14,820,009** | **$12.02** |
| AC-3 | RECORD-2 | 87 | 129,978 | 5,980,784 | 37,501 | **6,148,350** | **$5.08** |
| AC-4 | RECORD-2 | 87 | 129,978 | 5,980,784 | 37,501 | **6,148,350** | **$5.08** |
| AC-5 | RECORD-3 | 118 | 158,296 | 5,597,538 | 28,170 | **5,784,122** | **$4.89** |
| AC-6 | EXCHANGE-2 | 136 | 268,740 | 8,787,575 | 52,651 | **9,109,102** | **$8.03** |
| AC-7 | EXCHANGE-3 | 104 | 214,181 | 5,051,255 | 35,217 | **5,300,757** | **$5.21** |
| AC-8 | MERGE-3 | 57 | 115,269 | 3,002,378 | 24,657 | **3,142,362** | **$3.12** |
| AC-9 | MERGE-4 | 110 | 253,956 | 6,774,672 | 48,443 | **7,077,181** | **$6.76** |
| AC-10 | MERGE-2 | 126 | 191,760 | 6,067,585 | 30,747 | **6,290,218** | **$5.45** |
| AC-11 | MERGE-3 | 57 | 115,269 | 3,002,378 | 24,657 | **3,142,362** | **$3.12** |
| AC-12 | MERGE-5 | 124 | 266,710 | 7,314,260 | 46,046 | **7,627,140** | **$7.10** |
| **Direct total** |  | 1,398 | 2,516,313 | 89,848,615 | 549,752 | **92,916,078** | **$80.52** |

**Shared work** (spread evenly: $7.29 and 7,888,793 tokens per AC):

| Bucket | Input | Cache write | Cache read | Output | Total tokens | Cost |
|---|---:|---:|---:|---:|---:|---:|
| activities (plan, reconcile, sign-off decision) | 98 | 197,160 | 6,137,500 | 63,210 | 6,397,968 | $6.33 |
| scaffold | 116 | 120,199 | 6,041,574 | 47,630 | 6,209,519 | $5.41 |
| shell | 434 | 502,144 | 24,804,678 | 188,781 | 25,496,037 | $22.15 |
| acceptance-tests | 356 | 981,300 | 24,244,444 | 265,586 | 25,491,686 | $27.55 |
| test-review | 48 | 76,326 | 1,913,214 | 16,107 | 2,005,695 | $2.12 |
| sign-off | 206 | 366,057 | 11,200,516 | 69,177 | 11,635,956 | $10.41 |
| behavior (*enabler*) | 194 | 222,475 | 17,095,029 | 110,961 | 17,428,659 | $13.55 |
| **Shared total** | 1,452 | 2,465,661 | 91,436,955 | 761,452 | **94,665,520** | **$87.53** |

<details><summary>How each phase's <i>Target AC</i> was read</summary>

| Phase | Kind | Target AC (as written) | Attributed to |
|---|---|---|---|
| CORE-1 | scaffold | — | shared |
| CORE-2 | shell | — | shared |
| CORE-3 | behavior | AC-1 | AC-1 |
| CORE-4 | behavior | AC-2 | AC-2 |
| EXCHANGE-1 | shell | — | shared |
| EXCHANGE-2 | behavior | AC-6 | AC-6 |
| EXCHANGE-3 | behavior | AC-7 | AC-7 |
| EXCHANGE-4 | behavior (*enabler*) | — | shared |
| ITEST-1 | acceptance-tests | — (harness) | shared |
| ITEST-2 | acceptance-tests | AC-1..5 | shared |
| ITEST-3 | acceptance-tests | AC-6, AC-7, AC-10 | shared |
| ITEST-4 | acceptance-tests | AC-8, AC-9, AC-11, AC-12 | shared |
| ITEST-5 | test-review | — (G-2) | shared |
| MERGE-1 | shell | — | shared |
| MERGE-2 | behavior | AC-10 | AC-10 |
| MERGE-3 | behavior | AC-8 + AC-11 | AC-8, AC-11 |
| MERGE-4 | behavior | AC-9 | AC-9 |
| MERGE-5 | behavior | AC-12 | AC-12 |
| RECORD-1 | shell | — | shared |
| RECORD-2 | behavior | AC-3 + AC-4 | AC-3, AC-4 |
| RECORD-3 | behavior | AC-5 | AC-5 |

</details>

Generated by `ac_cost.py --plan /Users/matthew.quirk/Nuance-bs14/specs/bs-14-peer-to-peer-evidence-sharing/MASTER_PLAN_FOR_FEATURE.md`. Token cells are rounded; rows may differ from the totals by a few tokens.
