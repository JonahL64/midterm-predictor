# Midterm Simulator: Exam Prep + Boot.dev Project Plan

**Tonight (5:00 PM to 2:00 AM):** build the database by hand as CS 4750 exam prep.
**Tomorrow (after the 9:00 AM exam):** build the Python Monte Carlo on top of it for Boot.dev Personal Project 1.

**Ground rules for tonight**
- Write every `CREATE TABLE`, trigger, and procedure yourself. Typing it is the studying.
- Use MySQL (CS server, XAMPP, or GCP), not SQLite. The exam covers `DELIMITER`, triggers, stored procedures, and `ANY`/`ALL`.
- Before running any query, predict its output on paper. Once it runs, a wrong prediction is the most useful thing that can happen.
- If you are debugging setup or data loading for more than 10 minutes, stop and move to the next block.

---

## Timeline at a glance

| Time | Block | Output |
|---|---|---|
| 5:00 to 5:20 | 1. ER diagram on paper | Diagram with cardinalities, weak entities, total participation |
| 5:20 to 6:30 | 2. DDL by hand | `schema.sql` that runs clean |
| 6:30 to 6:50 | 3. Seed data | `seed.sql` loaded, edge cases included |
| 6:50 to 7:00 | 4. Constraint tests | Every "should fail" insert fails |
| 7:00 to 7:30 | 5. Triggers + procedures | `logic.sql`, each one tested |
| 7:30 to 8:15 | Dinner | Away from the screen |
| 8:15 to 10:15 | 6. Query checklist | `queries.sql` with ~30 queries, predicted then run |
| 10:15 to 10:30 | Break | |
| 10:30 to 11:30 | 7. Timed mock exam | Paper answers, then checked by running |
| 11:30 to 12:15 | 8. Fix what you missed | Redo only wrong answers + untouched slide examples |
| 12:15 to 12:45 | 9. Final concept pass | Section 9 checklist, say each answer out loud |
| 12:45 to 2:00 | 10. Optional Python start | Connection + poll average query. Skip if tired. |

---

## Block 1: ER diagram (5:00 to 5:20)

Draw on paper, exam style. Before moving on, confirm the diagram includes each of these:

- [ ] Entity sets: State, District, Party, Candidate, Race, Pollster, Poll
- [ ] **Weak entity:** District, identified by (state, district number). Draw the double box and the identifying relationship.
- [ ] **Weak entity:** PollResult, identified by (poll, candidate)
- [ ] **Multivalued attribute:** District has many counties (double oval)
- [ ] **Many to many:** Candidate runs in Race (with attributes `is_incumbent`, `votes`)
- [ ] **One to many:** Party has many Candidates; Race has many Polls; Pollster conducts many Polls
- [ ] **One to one:** District has at most one incumbent Candidate, and a Candidate is the incumbent of at most one District
- [ ] **Total participation:** every Candidate belongs to a Party; every Race is in a State; every Poll is about a Race (double line)
- [ ] **Recursive relationship:** Candidate endorses Candidate

For each relationship, write the conversion choice you will use (separate table vs. FK on the "many" side) and why. The slides ask exactly this question ("Do we need all these tables?").

---

## Block 2: DDL by hand (5:20 to 6:30)

Create the tables in this order, since FKs need their targets to exist first. The spec below gives columns and constraints. You write the SQL.

### 2.1 `state`
| Column | Type | Constraint |
|---|---|---|
| state_code | CHAR(2) | PK |
| name | VARCHAR(40) | NOT NULL |
| region | VARCHAR(20) | |

### 2.2 `party`
| Column | Type | Constraint |
|---|---|---|
| party_id | INT | PK |
| name | VARCHAR(40) | NOT NULL, UNIQUE |
| abbrev | CHAR(1) | NOT NULL, UNIQUE |

### 2.3 `candidate`
| Column | Type | Constraint |
|---|---|---|
| candidate_id | INT | PK, AUTO_INCREMENT |
| first_name | VARCHAR(30) | NOT NULL |
| last_name | VARCHAR(30) | NOT NULL |
| birth_date | DATE | |
| party_id | INT | **NOT NULL**, FK → party (total participation) |
| endorsed_by | INT | FK → candidate(candidate_id), **ON DELETE SET NULL** (self reference) |

### 2.4 `district` (weak entity + 1:1)
| Column | Type | Constraint |
|---|---|---|
| state_code | CHAR(2) | FK → state, part of PK |
| district_num | INT | part of PK, **attribute CHECK** `district_num >= 1` |
| pvi | DECIMAL(4,1) | partisan lean, negative = R, positive = D |
| incumbent_id | INT | **UNIQUE**, FK → candidate, ON DELETE SET NULL (1:1) |

PK: `(state_code, district_num)`

### 2.5 `district_county` (multivalued attribute)
| Column | Type | Constraint |
|---|---|---|
| state_code | CHAR(2) | |
| district_num | INT | |
| county | VARCHAR(40) | |

PK: all three columns. Composite FK `(state_code, district_num)` → district, **ON DELETE CASCADE**.

### 2.6 `race`
| Column | Type | Constraint |
|---|---|---|
| race_id | INT | PK, AUTO_INCREMENT |
| chamber | VARCHAR(6) | NOT NULL, CHECK `IN ('House','Senate')` |
| cycle_year | INT | NOT NULL, CHECK `cycle_year % 2 = 0` |
| state_code | CHAR(2) | **NOT NULL**, FK → state |
| district_num | INT | NULL for Senate races |
| rating | VARCHAR(10) | CHECK `IN ('Safe D','Likely D','Lean D','Toss-up','Lean R','Likely R','Safe R')` |
| win_prob_d | DECIMAL(4,3) | |

Composite FK `(state_code, district_num)` → district.

**Tuple-based CHECK (name it `chk_chamber_district`):**
House races must have a district and Senate races must not:
`(chamber = 'House' AND district_num IS NOT NULL) OR (chamber = 'Senate' AND district_num IS NULL)`

### 2.7 `candidacy` (many to many junction)
| Column | Type | Constraint |
|---|---|---|
| candidate_id | INT | FK → candidate, ON DELETE CASCADE |
| race_id | INT | FK → race, **ON DELETE CASCADE** |
| is_incumbent | BOOLEAN | DEFAULT FALSE |
| votes | INT | NULL until results are in |

PK: `(candidate_id, race_id)`

### 2.8 `pollster`
| Column | Type | Constraint |
|---|---|---|
| pollster_id | INT | PK |
| name | VARCHAR(50) | NOT NULL, UNIQUE |
| grade | CHAR(2) | |

### 2.9 `poll`
| Column | Type | Constraint |
|---|---|---|
| poll_id | INT | PK, AUTO_INCREMENT |
| race_id | INT | **NOT NULL**, FK → race, ON DELETE CASCADE |
| pollster_id | INT | FK → pollster, **ON DELETE SET NULL** |
| start_date | DATE | NOT NULL |
| end_date | DATE | NOT NULL |
| sample_size | INT | NOT NULL |
| weight | DECIMAL(6,3) | filled by trigger, Block 5 |

**Tuple-based CHECK (name it `chk_poll_valid`):** `end_date >= start_date AND sample_size > 0`

### 2.10 `poll_result` (weak entity)
| Column | Type | Constraint |
|---|---|---|
| poll_id | INT | FK → poll, ON DELETE CASCADE |
| candidate_id | INT | FK → candidate |
| share | DECIMAL(4,1) | CHECK `share BETWEEN 0 AND 100` |

PK: `(poll_id, candidate_id)`

### 2.11 `rating_changes` (log table)
| Column | Type | Constraint |
|---|---|---|
| race_id | INT | |
| changed_at | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| old_rating | VARCHAR(10) | |
| new_rating | VARCHAR(10) | |

PK: `(race_id, changed_at)`

### 2.12 ALTER practice (do these after everything runs)
1. `ALTER TABLE candidate ADD` a `website VARCHAR(100)` column, then `DROP` it.
2. Drop the named FK on `poll.pollster_id` and re-add it with `ADD CONSTRAINT fk_poll_pollster ... ON DELETE SET NULL`.
3. Drop `chk_poll_valid` and re-add it.

**Done when:** `schema.sql` runs top to bottom on an empty database with zero errors. Add `DROP TABLE IF EXISTS` lines at the top in reverse dependency order so you can rerun it.

---

## Block 3: Seed data (6:30 to 6:50)

Send me your final `CREATE TABLE`s and I'll write `seed.sql` to match your exact column names. These edge cases are deliberate, so check they made it in:

- [ ] 5 states, 15 districts, 3 Senate races, all `cycle_year = 2026`
- [ ] A few candidates who also have a **2024** candidacy, which justifies the many to many
- [ ] One **open seat**: a district with `incumbent_id` NULL
- [ ] One race with **zero polls** (tests outer joins and 0 counts)
- [ ] One poll with `pollster_id` NULL (tests `COUNT(*)` vs `COUNT(col)`)
- [ ] One candidacy with `votes` NULL (tests NULL in aggregates)
- [ ] One candidate who is **not** in `candidacy` at all (tests `NOT IN`/`NOT EXISTS`)
- [ ] Two polls in the same race **tied** on sample size (tests "highest per group" returning multiple rows)
- [ ] A few `endorsed_by` chains (tests self joins)
- [ ] A third party with at least one candidate

---

## Block 4: Constraint tests (6:50 to 7:00)

Each of these should **fail**. Predict the error before running.

1. Insert a candidate with `party_id` NULL.
2. Insert a candidate with a `party_id` that doesn't exist.
3. Insert a House race with `district_num` NULL.
4. Insert a Senate race with `district_num = 3`.
5. Insert a poll with `end_date` before `start_date`.
6. Insert a poll result with `share = 105`.
7. Set two districts' `incumbent_id` to the same candidate (UNIQUE).
8. Delete a party that still has candidates (default reject policy).

Each of these should **succeed**, with a side effect. Verify it with a `SELECT`.

9. Delete a pollster, then confirm its polls now have `pollster_id` NULL.
10. Delete a race, then confirm its candidacies, polls, and poll results are gone (cascade chain).
11. Delete a candidate who endorsed others, then confirm `endorsed_by` became NULL.

Reload the seed after the deletes.

---

## Block 5: Triggers and procedures (7:00 to 7:30)

Remember `DELIMITER $$ ... $$ DELIMITER ;` and the spaces the slides call out.

### 5.1 `BEFORE INSERT` trigger: compute a derived column (gradebook pattern)
`trg_poll_weight` on `poll`: set `NEW.weight = SQRT(NEW.sample_size) / 10`.
**Test:** insert a poll with `weight = 999`. It should be stored as the computed value.

### 5.2 `BEFORE UPDATE` trigger: clamp a value
`trg_race_clamp` on `race`: if `NEW.win_prob_d > 1`, set it to 1; if `< 0`, set it to 0.
**Test:** `UPDATE race SET win_prob_d = 1.7 WHERE race_id = 1;` should store 1.000.

### 5.3 `BEFORE UPDATE` trigger: log changes (salary_changes pattern)
`trg_rating_log` on `race`: if the rating changed, insert `(OLD.race_id, OLD.rating, NEW.rating)` into `rating_changes`.

Use `IF NOT (NEW.rating <=> OLD.rating)` rather than `NEW.rating <> OLD.rating`. Work out why before testing: what does `NULL <> 'Toss-up'` evaluate to?

**Test:** change a rating and confirm one log row appears. Set it to the same value and confirm no row appears. Change a NULL rating and confirm it logs.

> MySQL allows only one `BEFORE UPDATE` trigger per table on older versions. If 5.2 and 5.3 conflict, merge them into one trigger body. Merging is good practice anyway.

### 5.4 Procedure with OUT
`seatsRated(IN p_party CHAR(1), IN p_chamber VARCHAR(6), OUT n INT)`: count races in that chamber whose rating ends in the party letter (Safe, Likely, or Lean).
**Test:** `CALL seatsRated('D', 'House', @n); SELECT @n;`

### 5.5 Procedure with IN only
`updateRating(IN p_race INT, IN p_rating VARCHAR(10))`: updates one race's rating.
**Test:** call it, then confirm `rating_changes` got a row. Your procedure just fired your trigger.

### 5.6 Housekeeping
Run `SHOW TRIGGERS;`, `DROP TRIGGER IF EXISTS ...;`, `DROP PROCEDURE IF EXISTS ...;` at least once each.

---

## Block 6: Query checklist (8:15 to 10:15)

Save everything in `queries.sql`. For each one: write it, **predict the output on paper**, run it, and compare. Mark each ✅ (right first time) or ❌ (wrong prediction).

### 6.1 Basics (SQL Basics deck)
1. All candidates whose last name starts with "M", ordered by last name, then first name descending.
2. Distinct regions that have at least one state.
3. Each poll's field period in days, aliased `days_in_field`.
4. Candidate IDs that appear in both the 2024 and 2026 cycles, using `INTERSECT`.
5. All candidate IDs in House races `UNION` all candidate IDs in Senate races. Then use `UNION ALL` and explain the row count difference.

### 6.2 Aggregates (Aggregates deck)
6. Number of candidates per party.
7. Average poll sample size per pollster, only for pollsters with 3 or more polls, highest first.
8. `COUNT(*)`, `COUNT(pollster_id)`, and `COUNT(DISTINCT pollster_id)` on `poll` in one query. Explain all three numbers.
9. `SUM(votes)` and `AVG(votes)` on `candidacy`. Does the NULL row change the average? Why?
10. Number of races per rating, excluding Senate races, only ratings with more than one race.

### 6.3 Joins (Join deck)
11. Each candidate's full name and party name (inner join).
12. Same with `NATURAL JOIN`. Count the columns in each result. Then explain what a natural join would do if two tables shared a column named `name`.
13. Every race with its number of polls, **including races with 0 polls** (`LEFT JOIN`).
14. The same query with an inner join. Which race disappeared?
15. Each candidate and the name of who endorsed them (self join). Then make it include candidates with no endorser.
16. Candidates who ran in **both** a 2024 race and a 2026 race, using a self join on `candidacy` (the "Database Systems and Software Analysis" pattern).
17. Number of polls per state per chamber (three-table join + `GROUP BY` on two columns).

### 6.4 Subqueries (Subqueries deck)
18. For each poll, its sample size and the **average sample size in that race**:
    a. correlated subquery in `SELECT`
    b. subquery in `FROM`
    c. `WITH`
19. The poll(s) with the **largest sample size per race**, four ways:
    a. correlated subquery in `WHERE`
    b. subquery in `FROM` joined back
    c. `WITH`
    d. self join with `GROUP BY ... HAVING` (Option 1 from the slides)
    Confirm all four return the tie you seeded.
20. Candidates who ran **only** in House races and never Senate, with `EXCEPT`.
21. Same as 20, with the `LEFT JOIN ... WHERE ... IS NULL` workaround.
22. Same as 4, with the inner join + `DISTINCT` workaround for `INTERSECT`.

### 6.5 Quantifiers (Subqueries in WHERE deck)
23. Pollsters with **some** poll over 1,000 respondents: once with `IN`, once with `EXISTS`, once with `ANY`.
24. Pollsters whose polls are **all** over 800 respondents: once with `NOT IN`, once with `NOT EXISTS`, once with `ALL`.
25. Candidates who have never been in any candidacy: `NOT IN` and `NOT EXISTS`.
26. **The NULL trap:** run 25's `NOT IN` version against a subquery that can return a NULL, e.g. `WHERE candidate_id NOT IN (SELECT endorsed_by FROM candidate)`. Compare with `NOT EXISTS`. Explain the difference.
27. Races where the leading candidate in **every** poll is from the same party (hard; give it 10 minutes max).

### 6.6 DML
28. `UPDATE` all Toss-up races to `win_prob_d = 0.5`.
29. `DELETE` polls older than 30 days before election day. Then reload the seed.
30. On a scratch copy table, compare `DELETE FROM`, `TRUNCATE`, and `DROP`. Check whether `AUTO_INCREMENT` resets and whether `ROLLBACK` works after `START TRANSACTION`.

---

## Block 7: Timed mock exam (10:30 to 11:30)

Send me your final schema by ~10:15 and I'll write 12 to 15 exam style questions against it.

Rules:
- 45 minutes, on paper, nothing running.
- Then 15 minutes executing your answers to grade yourself.
- Anything you got wrong goes on the Block 8 list.

---

## Block 8: Fix what you missed (11:30 to 12:15)

1. Redo every ❌ from Block 6 and every miss from Block 7 from scratch, without looking at your earlier attempt.
2. Skim the slide decks for any example pattern you never wrote yourself, and write it against your schema.

---

## Block 9: Final concept pass (12:15 to 12:45)

Say each answer out loud without notes.

1. Order of execution: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY. Why can't `WHERE` use an aggregate?
2. `WHERE` vs. `HAVING`.
3. `DROP` vs. `TRUNCATE` vs. `DELETE`: DDL or DML, rollback, `AUTO_INCREMENT`, `WHERE`.
4. DDL vs. DML vs. DCL vs. TCL, with two commands each.
5. Natural join vs. inner join: which columns appear, and what natural join matches on.
6. Correlated vs. uncorrelated subquery, with one example of each.
7. `COUNT(*)` vs. `COUNT(col)` vs. `COUNT(DISTINCT col)`.
8. What every aggregate except `COUNT` returns on an empty set (NULL), and what `COUNT` returns (0).
9. The three referential integrity policies: reject, cascade, set null.
10. Attribute-based vs. tuple-based `CHECK`.
11. Trigger parts: event, timing (BEFORE/AFTER), table, `FOR EACH ROW`, body. What are `NEW` and `OLD`?
12. When triggers help (read-heavy) vs. hurt (write-heavy).
13. Stored procedure: `IN` vs. `OUT`, `CALL` with `@vars`, `DROP PROCEDURE IF EXISTS`.
14. ER → tables: when a relationship gets its own table vs. becomes an FK; how to enforce 1:1 (UNIQUE), total participation (NOT NULL), and weak entities (composite PK including the owner key).
15. `NOT IN` with a NULL in the subquery.

---

## Block 10: Optional Python start (12:45 to 2:00)

Only if Block 9 felt solid. Otherwise stop and sleep.

1. `pip install mysql-connector-python` (or `PyMySQL`)
2. `db.py` with a `get_connection()` function reading credentials from environment variables, never hardcoded
3. One function that returns, for each race, the **weighted average two-party margin** across its polls (D share minus R share, weighted by `poll.weight`)
4. Print it for every race. Confirm the zero-poll race is handled (fall back to the district's `pvi`)

---

## Tomorrow: Boot.dev Personal Project 1 (after the exam)

### Project structure
```
midterm-sim/
  sql/
    schema.sql
    seed.sql
    logic.sql
  sim/
    db.py
    polls.py
    simulate.py
    report.py
  tests/
    test_polls.py
    test_simulate.py
  main.py
  README.md
```

### Steps
1. **Polls → priors.** For each race: weighted poll margin if polls exist, otherwise `pvi` as the prior. Optionally blend the two by number of polls.
2. **Simulation model.** For each of N = 10,000 runs:
   - draw one **national error** shared by every race in that run
   - for each race, draw a **race-level error**
   - simulated margin = prior + national error + race error
   - D wins the race if the margin > 0
3. **Tally.** Seats won per party per run, for the House and the Senate separately.
4. **Write back.** Add `sim_run(run_id, created_at, n_sims, national_sd, race_sd)` and `sim_result(run_id, race_id, d_win_prob)`. Update `race.win_prob_d` through the procedure, so the clamp trigger and the rating log both get exercised by real code.
5. **Report.** CLI summary: probability each party controls each chamber, median seats, 80% interval, and the 10 closest races. Plus a histogram of House seat counts saved as a PNG.
6. **Tests.** Prior calculation with and without polls; a seeded simulation run is deterministic; a race with prior +50 is won in essentially 100% of sims.
7. **README.** What it does, how to run it, the schema diagram, and a paragraph on **why the shared national error matters**: without it, races are independent coin flips and the seat distribution comes out unrealistically narrow. That design choice is the interesting part of the project.

### Stretch goals
- Command line flags for N, national SD, and race SD
- Compare results with and without the national error term
- Swap synthetic polls for real ones later
