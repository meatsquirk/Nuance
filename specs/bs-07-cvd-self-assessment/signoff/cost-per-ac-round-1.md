### Cost per AC

Tokens from the *Token usage* ledger (29 sessions, 221,239,688 tokens); cost at API list rates as of 2026-09-25 (USD per million tokens; cache writes at 1.25× input for 5-minute and 2× for 1-hour entries). Feature total **$192.27**: input $0.02, cache write $49.19, cache read $107.20, output $35.87. 29 of 29 sessions priced from their transcripts.

**Fully loaded** (direct, plus an even 1/14 share of all shared work; sums to the feature total):

| AC | Direct phases | Input | Cache write | Cache read | Output | Total tokens | Cost |
|---|---|---:|---:|---:|---:|---:|---:|
| AC-1 | FLOW-8 | 233 | 403,997 | 13,198,295 | 84,518 | **13,687,042** | **$12.26** |
| AC-2 | FLOW-3 | 247 | 363,985 | 13,989,270 | 104,206 | **14,457,707** | **$13.00** |
| AC-3 | ENGINE-3 | 241 | 418,483 | 14,728,570 | 110,464 | **15,257,757** | **$14.05** |
| AC-4 | ENGINE-4 | 305 | 417,584 | 18,240,640 | 108,630 | **18,767,159** | **$15.57** |
| AC-5 | ENGINE-5 | 307 | 479,638 | 22,026,064 | 123,506 | **22,629,515** | **$18.42** |
| AC-6 | FLOW-4 | 158 | 274,764 | 10,833,326 | 79,778 | **11,188,026** | **$9.93** |
| AC-7 | FLOW-4 | 158 | 274,764 | 10,833,326 | 79,778 | **11,188,026** | **$9.93** |
| AC-8 | FLOW-4 | 158 | 274,764 | 10,833,326 | 79,778 | **11,188,026** | **$9.93** |
| AC-9 | ENGINE-6 | 239 | 401,719 | 14,722,126 | 100,820 | **15,224,904** | **$13.52** |
| AC-10 | FLOW-6 | 269 | 396,772 | 15,920,399 | 100,608 | **16,418,047** | **$14.02** |
| AC-11 | ENGINE-7 | 267 | 417,368 | 16,618,445 | 114,304 | **17,150,383** | **$14.93** |
| AC-12 | FLOW-7 | 285 | 439,333 | 18,614,584 | 121,446 | **19,175,648** | **$16.29** |
| AC-13 | PROFILE-2 | 247 | 416,092 | 20,096,741 | 124,326 | **20,637,406** | **$17.19** |
| AC-14 | FLOW-2 | 233 | 431,965 | 13,735,321 | 102,522 | **14,270,040** | **$13.23** |
| **Total** |  | 3,346 | 5,411,229 | 214,390,429 | 1,434,684 | **221,239,688** | **$192.27** |

**Direct** (behavior phases only, each split evenly across the ACs its *Target AC* names):

| AC | Phases | Input | Cache write | Cache read | Output | Total tokens | Cost |
|---|---|---:|---:|---:|---:|---:|---:|
| AC-1 | FLOW-8 | 132 | 231,117 | 7,193,177 | 34,121 | **7,458,547** | **$6.40** |
| AC-2 | FLOW-3 | 146 | 191,105 | 7,984,152 | 53,809 | **8,229,212** | **$7.14** |
| AC-3 | ENGINE-3 | 140 | 245,603 | 8,723,452 | 60,067 | **9,029,262** | **$8.19** |
| AC-4 | ENGINE-4 | 204 | 244,704 | 12,235,522 | 58,234 | **12,538,664** | **$9.71** |
| AC-5 | ENGINE-5 | 206 | 306,758 | 16,020,946 | 73,110 | **16,401,020** | **$12.56** |
| AC-6 | FLOW-4 | 57 | 101,884 | 4,828,208 | 29,382 | **4,959,530** | **$4.07** |
| AC-7 | FLOW-4 | 57 | 101,884 | 4,828,208 | 29,382 | **4,959,530** | **$4.07** |
| AC-8 | FLOW-4 | 57 | 101,884 | 4,828,208 | 29,382 | **4,959,530** | **$4.07** |
| AC-9 | ENGINE-6 | 138 | 228,839 | 8,717,008 | 50,424 | **8,996,409** | **$7.66** |
| AC-10 | FLOW-6 | 168 | 223,892 | 9,915,281 | 50,211 | **10,189,552** | **$8.17** |
| AC-11 | ENGINE-7 | 166 | 244,488 | 10,613,327 | 63,907 | **10,921,888** | **$9.07** |
| AC-12 | FLOW-7 | 184 | 266,453 | 12,609,466 | 71,050 | **12,947,153** | **$10.43** |
| AC-13 | PROFILE-2 | 146 | 243,212 | 14,091,623 | 73,930 | **14,408,911** | **$11.33** |
| AC-14 | FLOW-2 | 132 | 259,085 | 7,730,203 | 52,125 | **8,041,545** | **$7.37** |
| **Direct total** |  | 1,932 | 2,990,908 | 130,318,781 | 729,133 | **134,040,754** | **$110.25** |

**Shared work** (spread evenly: $5.86 and 6,228,495 tokens per AC):

| Bucket | Input | Cache write | Cache read | Output | Total tokens | Cost |
|---|---:|---:|---:|---:|---:|---:|
| activities (plan, reconcile, sign-off decision) | 346 | 572,839 | 13,340,060 | 170,964 | 14,084,209 | $16.33 |
| scaffold | 78 | 89,922 | 3,495,346 | 34,357 | 3,619,703 | $3.51 |
| shell | 388 | 413,681 | 24,061,130 | 169,868 | 24,645,067 | $20.42 |
| acceptance-tests | 320 | 750,855 | 23,475,799 | 216,155 | 24,443,129 | $23.94 |
| test-review | 22 | 64,372 | 771,555 | 11,809 | 847,758 | $1.32 |
| sign-off | 100 | 253,867 | 7,598,157 | 38,002 | 7,890,126 | $6.76 |
| behavior phases naming no AC | 160 | 274,785 | 11,329,601 | 64,396 | 11,668,942 | $9.75 |
| **Shared total** | 1,414 | 2,420,321 | 84,071,648 | 705,551 | **87,198,934** | **$82.02** |

<details><summary>How each phase's <i>Target AC</i> was read</summary>

| Phase | Kind | Target AC (as written) | Attributed to |
|---|---|---|---|
| ENGINE-1 | scaffold | — | shared |
| ENGINE-2 | shell | — | shared |
| ENGINE-3 | behavior | AC-3 | AC-3 |
| ENGINE-4 | behavior | AC-4 | AC-4 |
| ENGINE-5 | behavior | AC-5 | AC-5 |
| ENGINE-6 | behavior | AC-9 | AC-9 |
| ENGINE-7 | behavior | AC-11 | AC-11 |
| FLOW-1 | shell | — | shared |
| FLOW-2 | behavior | AC-14 | AC-14 |
| FLOW-3 | behavior | AC-2 | AC-2 |
| FLOW-4 | behavior | AC-6, AC-7, AC-8 | AC-6, AC-7, AC-8 |
| FLOW-5 | behavior | — (enabler) | shared |
| FLOW-6 | behavior | AC-10 | AC-10 |
| FLOW-7 | behavior | AC-12 | AC-12 |
| FLOW-8 | behavior | AC-1 | AC-1 |
| ITEST-1 | acceptance-tests | — (harness + smoke) | shared |
| ITEST-2 | acceptance-tests | AC-1,2,10,11,12,13,14 | shared |
| ITEST-3 | acceptance-tests | AC-3,4,5,6,7,8,9 | shared |
| ITEST-4 | test-review | — (G-2) | shared |
| PROFILE-1 | shell | — | shared |
| PROFILE-2 | behavior | AC-13 | AC-13 |

</details>

Generated by `ac_cost.py --plan specs/bs-07-cvd-self-assessment/MASTER_PLAN_FOR_FEATURE.md`. Token cells are rounded; rows may differ from the totals by a few tokens.
