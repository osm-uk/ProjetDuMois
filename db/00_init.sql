-- User names
CREATE TABLE user_names(
	userid BIGINT PRIMARY KEY,
	username VARCHAR NOT NULL
);

CREATE INDEX user_names_userid_idx ON user_names(userid);

-- User contributions through all projects
CREATE TABLE user_contributions(
	project VARCHAR NOT NULL,
	userid BIGINT NOT NULL,
	ts TIMESTAMP NOT NULL,
	contribution VARCHAR NOT NULL,
	verified BOOLEAN NOT NULL DEFAULT TRUE,
	points INT NOT NULL DEFAULT 1
);

CREATE INDEX user_contributions_project_idx ON user_contributions(project);
CREATE INDEX user_contributions_userid_idx ON user_contributions(userid);

-- User badges
DROP TABLE IF EXISTS user_badges;

-- Features counts
CREATE TABLE feature_counts(
	project VARCHAR NOT NULL,
	ts TIMESTAMP NOT NULL,
	amount INT NOT NULL
);

CREATE INDEX feature_counts_project_idx ON feature_counts(project);

-- Note counts
CREATE TABLE note_counts(
	project VARCHAR NOT NULL,
	ts TIMESTAMP NOT NULL,
	open INT NOT NULL,
	closed INT NOT NULL
);

CREATE INDEX note_counts_project_idx ON note_counts(project);

-- Extensions for Imposm
CREATE EXTENSION postgis;
CREATE EXTENSION hstore;

-- Leaderboard view
CREATE OR REPLACE VIEW leaderboard AS
WITH stats AS (
	SELECT userid, project, SUM(points) AS amount
	FROM user_contributions
	GROUP BY userid, project
	ORDER BY SUM(points) DESC
), scores AS (
	SELECT project, row_number() over (PARTITION BY project ORDER BY amount DESC) AS pos, amount
	FROM (
		SELECT DISTINCT project, amount
		FROM stats
		ORDER BY project, amount DESC
	) a
)
SELECT st.project, st.userid, un.username, st.amount, sc.pos
FROM stats st
JOIN scores sc ON st.project = sc.project AND sc.amount = st.amount
JOIN user_names un ON st.userid = un.userid;

-- OSM compare feature exclusions
CREATE TABLE osm_compare_exclusions(
	project VARCHAR NOT NULL,
	osm_id VARCHAR NOT NULL,
	ts TIMESTAMP NOT NULL DEFAULT current_timestamp,
	userid BIGINT,
	CONSTRAINT osm_compare_exclusions_pk PRIMARY KEY(project, osm_id)
);

-- Helpers links
CREATE TABLE user_helpers(
	id BIGSERIAL PRIMARY KEY,
	userid BIGINT NOT NULL,
	helpername VARCHAR NOT NULL,
	shortcode VARCHAR NOT NULL UNIQUE,
	labels JSONB
);

CREATE INDEX user_helpers_userid_idx ON user_helpers(userid);
CREATE INDEX user_helpers_shortcode_idx ON user_helpers(shortcode);

-- Helpers reports
CREATE TYPE helper_report_status AS ENUM ('new', 'checking', 'verified', 'duplicate', 'invalid');
CREATE TABLE helper_reports(
	id BIGSERIAL PRIMARY KEY,
	helperid BIGINT REFERENCES user_helpers(id),
	ts TIMESTAMP NOT NULL DEFAULT current_timestamp,
	report VARCHAR NOT NULL,
	picture VARCHAR,
	coordinates GEOMETRY(Point, 4326),
	status helper_report_status NOT NULL DEFAULT 'new',
	permission_picture BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX helper_reports_helperid_idx ON helper_reports(helperid);
