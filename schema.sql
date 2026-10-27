-- create tables

CREATE TABLE state (
    state_code CHAR(2) PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    region VARCHAR(20)
);

CREATE TABLE party (
    party_id INT PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    abbrev CHAR(1) NOT NULL UNIQUE
);

CREATE TABLE candidate (
    candidate_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    birth_date DATE,
    party_id INT NOT NULL,
    endorsed_by INT,
    CONSTRAINT candidate_to_party FOREIGN KEY (party_id) REFERENCES party(party_id),
    CONSTRAINT candidate_endorses_candidate FOREIGN KEY (endorsed_by) REFERENCES candidate(candidate_id) ON DELETE SET NULL
);

CREATE TABLE district (
    state_code CHAR(2),
    district_num INT,
    pvi DECIMAL(4,1), -- partisan lean
    incumbent_id INT UNIQUE,
    PRIMARY KEY(state_code, district_num),
    CONSTRAINT state_code_to_state FOREIGN KEY (state_code) REFERENCES state(state_code),
    CONSTRAINT incumbent_to_candidate FOREIGN KEY (incumbent_id) REFERENCES candidate(candidate_id) ON DELETE SET NULL
);

CREATE TABLE district_county (
    state_code CHAR(2),
    district_num INT,
    county VARCHAR(40),
    PRIMARY KEY(state_code, district_num, county),
    CONSTRAINT district_county_to_county FOREIGN KEY (state_code, district_num) REFERENCES district(state_code, district_num) ON DELETE CASCADE
);

CREATE TABLE race (
    race_id INT PRIMARY KEY AUTO_INCREMENT,
    chamber VARCHAR(6) NOT NULL,
    cycle_year INT NOT NULL,
    state_code CHAR(2) NOT NULL,
    district_num INT,
    rating VARCHAR(10),
    win_prob_d DECIMAL(4, 3),
    CONSTRAINT is_valid_chamber CHECK (chamber in ('House', 'Senate')),
    CONSTRAINT is_valid_cycle_year CHECK (cycle_year % 2 = 0),
    CONSTRAINT state_code_to_state_from_race FOREIGN KEY (state_code) REFERENCES state(state_code),
    CONSTRAINT is_valid_rating CHECK (rating in ('Safe D', 'Likely D', 'Lean D', 'Toss-up', 'Lean R', 'Likely R', 'Safe R')),
    CONSTRAINT race_to_district FOREIGN KEY (state_code, district_num) REFERENCES district(state_code, district_num),
    CONSTRAINT chk_chamber_district CHECK ((chamber = 'House' AND district_num IS NOT NULL) OR (chamber = 'Senate' AND district_num IS NULL))
);

CREATE TABLE candidacy (
    candidate_id INT,
    race_id INT,
    is_incumbent BOOLEAN DEFAULT FALSE,
    votes INT,
    CONSTRAINT to_race FOREIGN KEY (race_id) REFERENCES race(race_id) ON DELETE CASCADE,
    CONSTRAINT to_candidate FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id),
    PRIMARY KEY (candidate_id, race_id)
);

CREATE TABLE pollster (
    pollster_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    grade CHAR(2)
);

CREATE TABLE poll (
    poll_id INT PRIMARY KEY AUTO_INCREMENT,
    race_id INT NOT NULL,
    pollster_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    sample_size INT NOT NULL,
    weight DECIMAL(6,3),
    CONSTRAINT poll_to_race FOREIGN KEY (race_id) REFERENCES race(race_id) ON DELETE CASCADE,
    CONSTRAINT poll_to_pollster FOREIGN KEY (pollster_id) REFERENCES pollster(pollster_id) ON DELETE SET NULL,
    CONSTRAINT chk_poll_valid CHECK (end_date >= start_date AND sample_size > 0)
);

CREATE TABLE poll_result (
    poll_id INT,
    candidate_id INT,
    share DECIMAL(4,1),
    CONSTRAINT to_poll_from_poll_result FOREIGN KEY (poll_id) REFERENCES poll(poll_id) ON DELETE CASCADE,
    CONSTRAINT to_candidate_from_poll_result FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id),
    CONSTRAINT check_poll_result_valid CHECK (share BETWEEN 0 AND 100),
    PRIMARY KEY (poll_id, candidate_id)
);

CREATE TABLE rating_changes (
    race_id INT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    old_rating VARCHAR(10),
    new_rating VARCHAR(10),
    PRIMARY KEY (race_id, changed_at)
);
