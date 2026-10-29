-- create tables

DROP TABLE IF EXISTS sim_race_result, sim_chamber_result, sim_run, rating_changes, poll_result, poll, pollster, candidacy, holdover, race, district_county, district_lean, district, candidate, party, state_lean, state;
DROP PROCEDURE IF EXISTS seatsRated;
DROP PROCEDURE IF EXISTS updateRating;

CREATE TABLE state (
    state_code CHAR(2) PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    region VARCHAR(20)
);

CREATE TABLE state_lean (
    state_code CHAR(2),
    pres_cycle INT,
    lean DECIMAL(4,1),
    PRIMARY KEY(state_code, pres_cycle),
    CONSTRAINT state_lean_to_state FOREIGN KEY (state_code) REFERENCES state(state_code)
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
    map_cycle INT,
    PRIMARY KEY(state_code, district_num, map_cycle),
    CONSTRAINT state_code_to_state FOREIGN KEY (state_code) REFERENCES state(state_code)
);

CREATE TABLE district_lean (
    state_code CHAR(2),
    district_num INT,
    map_cycle INT,
    pres_cycle INT,
    lean DECIMAL(4, 1),
    PRIMARY KEY (state_code, pres_cycle, district_num, map_cycle),
    CONSTRAINT district_lean_to_district FOREIGN KEY (state_code, district_num, map_cycle) REFERENCES district(state_code, district_num, map_cycle)
);

CREATE TABLE district_county (
    state_code CHAR(2),
    district_num INT,
    county VARCHAR(40),
    map_cycle INT,
    PRIMARY KEY(state_code, district_num, county, map_cycle),
    CONSTRAINT district_county_to_county FOREIGN KEY (state_code, district_num, map_cycle) REFERENCES district(state_code, district_num, map_cycle) ON DELETE CASCADE
);

CREATE TABLE race (
    race_id INT PRIMARY KEY AUTO_INCREMENT,
    chamber VARCHAR(6) NOT NULL,
    cycle_year INT NOT NULL,
    state_code CHAR(2) NOT NULL,
    district_num INT,
    rating VARCHAR(10),
    win_prob_d DECIMAL(4, 3),
    map_cycle INT,
    actual_margin DECIMAL(5, 2),
    election_date DATE,
    is_special BOOLEAN DEFAULT FALSE,
    CONSTRAINT is_unique_race UNIQUE (cycle_year, chamber, state_code, district_num, is_special),
    CONSTRAINT is_valid_chamber CHECK (chamber in ('House', 'Senate')),
    CONSTRAINT is_valid_cycle_year CHECK (cycle_year % 2 = 0),
    CONSTRAINT state_code_to_state_from_race FOREIGN KEY (state_code) REFERENCES state(state_code),
    CONSTRAINT is_valid_rating CHECK (rating in ('Safe D', 'Likely D', 'Lean D', 'Toss-up', 'Lean R', 'Likely R', 'Safe R')),
    CONSTRAINT race_to_district FOREIGN KEY (state_code, district_num, map_cycle) REFERENCES district(state_code, district_num, map_cycle),
    CONSTRAINT chk_chamber_district CHECK ((chamber = 'House' AND district_num IS NOT NULL) OR (chamber = 'Senate' AND district_num IS NULL))
);

CREATE TABLE candidacy (
    candidate_id INT,
    race_id INT,
    party_id INT,
    is_incumbent BOOLEAN DEFAULT FALSE,
    votes INT,
    is_winner BOOLEAN,
    CONSTRAINT candidacy_to_party FOREIGN KEY (party_id) REFERENCES party(party_id),
    CONSTRAINT to_race FOREIGN KEY (race_id) REFERENCES race(race_id) ON DELETE CASCADE,
    CONSTRAINT to_candidate FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id),
    PRIMARY KEY (candidate_id, race_id)
);

CREATE TABLE pollster (
    pollster_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    grade CHAR(2),
    rating_numeric DECIMAL(3, 2)
);

CREATE TABLE poll (
    poll_id INT PRIMARY KEY AUTO_INCREMENT,
    race_id INT NOT NULL,
    pollster_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    sample_size INT NOT NULL,
    weight DECIMAL(6,3),
    population VARCHAR(3),
    partisan_sponsor CHAR(1),
    poll_source VARCHAR(30),
    poll_url VARCHAR(255),
    CONSTRAINT poll_to_race FOREIGN KEY (race_id) REFERENCES race(race_id) ON DELETE CASCADE,
    CONSTRAINT poll_to_pollster FOREIGN KEY (pollster_id) REFERENCES pollster(pollster_id) ON DELETE SET NULL,
    CONSTRAINT chk_poll_valid CHECK (end_date >= start_date AND sample_size > 0),
    CONSTRAINT chk_poll_valid_population CHECK (population IN ('LV', 'RV', 'A', 'V'))
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

CREATE TABLE generic_ballot_poll (
    poll_id INT,
    pollster_id INT,
    end_date DATE,
    sample_size INT,
    population INT,
    dem_share DOUBLE(4,3),
    rep_share DOUBLE(4,3),
    CONSTRAINT generic_ballot_to_poll FOREIGN KEY (poll_id) REFERENCES poll(poll_id),
    CONSTRAINT generic_ballot_to_pollster FOREIGN KEY (pollster_id) REFERENCES pollster(pollster_id)
);

CREATE TABLE rating_changes (
    race_id INT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    old_rating VARCHAR(10),
    new_rating VARCHAR(10),
    PRIMARY KEY (race_id, changed_at)
);

CREATE TABLE holdover (
    cycle_year INT,
    chamber VARCHAR(6) NOT NULL,
    party_id INT,
    seats INT,
    PRIMARY KEY(cycle_year, party_id, chamber),
    CONSTRAINT hold_chk_chamber_district CHECK (chamber in ('House', 'Senate')),
    CONSTRAINT holdover_to_party FOREIGN KEY (party_id) REFERENCES party(party_id)
);

CREATE TABLE sim_run (
    run_id INT PRIMARY KEY AUTO_INCREMENT,
    cycle_year INT,
    as_of_date DATE,
    n_sims INT,
    seed INT,
    params_json JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sim_race_result (
    run_id INT,
    race_id INT,
    p_dem_win DECIMAL(4,3),
    mean_margin DECIMAL(5,2),
    PRIMARY KEY (run_id, race_id),
    CONSTRAINT sim_race_result_to_run FOREIGN KEY (run_id) REFERENCES sim_run(run_id) ON DELETE CASCADE,
    CONSTRAINT sim_race_result_to_race FOREIGN KEY (race_id) REFERENCES race(race_id)
);

CREATE TABLE sim_chamber_result (
    run_id INT,
    chamber VARCHAR(6) NOT NULL,
    p_dem_control DECIMAL(4,3),
    median_dem_seats INT,
    p10_dem_seats INT,
    p90_dem_seats INT,
    PRIMARY KEY (run_id, chamber),
    CONSTRAINT sim_chamber_result_to_run FOREIGN KEY (run_id) REFERENCES sim_run(run_id) ON DELETE CASCADE
);

CREATE INDEX idx_poll_race_date ON poll(race_id, end_date);

DELIMITER $$
CREATE TRIGGER trg_poll_weight
BEFORE INSERT on poll
FOR EACH ROW
    BEGIN
        SET NEW.weight = SQRT(NEW.sample_size) / 10;
    END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_race_clamp
BEFORE UPDATE ON race
FOR EACH ROW
    BEGIN
        IF NEW.win_prob_d > 1 THEN
            SET NEW.win_prob_d = 1.00;
        ELSEIF NEW.win_prob_d < 0 THEN
            SET NEW.win_prob_d = 0.00;
        END IF;
    END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_rating_log
AFTER UPDATE ON race
FOR EACH ROW
    BEGIN
        IF NOT (NEW.rating <=> OLD.rating) THEN
            INSERT INTO rating_changes (race_id, old_rating, new_rating)
            VALUES (OLD.race_id, OLD.rating, NEW.rating);
        END IF;
    END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE seatsRated(
    IN p_party CHAR(1),
    IN p_chamber VARCHAR(6),
    IN p_cycle_year INT,
    OUT n INT
)

BEGIN
    SELECT COUNT(*) INTO n
    FROM race
    WHERE rating LIKE CONCAT('%', p_party)
    AND chamber = p_chamber
    AND cycle_year = p_cycle_year;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE updateRating(
    IN p_race INT,
    IN p_rating VARCHAR(10)
)

BEGIN
    UPDATE race
    SET rating = p_rating
    WHERE p_race = race_id;
END$$

DELIMITER ;
