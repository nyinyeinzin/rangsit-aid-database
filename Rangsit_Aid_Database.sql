-- =====================================================================
-- RANGSIT Aid System Database  (university project, 2024)
-- Author: Nyi Nyein Zin
-- 15 tables, 4 views, 3 stored procedures.
-- Tested with MariaDB 10.11 and MySQL 8.0.46.
-- Run once with permission to create a new database.
-- =====================================================================

CREATE DATABASE rangsit_aid CHARACTER SET utf8mb4;
USE rangsit_aid;

-- ---------------------------------------------------------------------
-- 1. TABLES (parent tables first, so foreign keys work)
-- ---------------------------------------------------------------------

CREATE TABLE organization (
  organizationID INT NOT NULL AUTO_INCREMENT,
  name           VARCHAR(255) NOT NULL,
  address        VARCHAR(255) NOT NULL,
  email          VARCHAR(255) NOT NULL,
  phone_number   VARCHAR(20)  NOT NULL,
  PRIMARY KEY (organizationID),
  UNIQUE KEY uq_organization_email (email)
) ENGINE=InnoDB;

-- Contribution amounts are recorded with individual cash gifts.
CREATE TABLE donor (
  donorID      INT NOT NULL AUTO_INCREMENT,
  name         VARCHAR(255) NOT NULL,
  address      VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20)  NOT NULL,
  PRIMARY KEY (donorID)
) ENGINE=InnoDB;

CREATE TABLE applicant (
  applicantID  INT NOT NULL AUTO_INCREMENT,
  full_name    VARCHAR(100) NOT NULL,
  address      VARCHAR(255) NOT NULL,
  email        VARCHAR(255),
  phone_number VARCHAR(20)  NOT NULL,
  income       DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (applicantID),
  CONSTRAINT chk_applicant_income CHECK (income >= 0)
) ENGINE=InnoDB;

CREATE TABLE `user` (
  userID         INT NOT NULL AUTO_INCREMENT,
  username       VARCHAR(50)  NOT NULL,
  passport       VARCHAR(20)  NOT NULL,
  full_name      VARCHAR(100) NOT NULL,
  address        VARCHAR(255) NOT NULL,
  email          VARCHAR(100) NOT NULL,
  phone_number   VARCHAR(20)  NOT NULL,
  organizationID INT,
  PRIMARY KEY (userID),
  UNIQUE KEY uq_user_username (username),
  UNIQUE KEY uq_user_org (userID, organizationID),
  CONSTRAINT fk_user_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID)
) ENGINE=InnoDB;

CREATE TABLE appeal (
  appealID       INT NOT NULL AUTO_INCREMENT,
  starting_date  DATE NOT NULL,
  ending_date    DATE NOT NULL,
  status         VARCHAR(20) NOT NULL,
  description    TEXT NOT NULL,
  organizationID INT NOT NULL,
  PRIMARY KEY (appealID),
  UNIQUE KEY uq_appeal_org (appealID, organizationID),
  CONSTRAINT chk_appeal_dates CHECK (ending_date >= starting_date),
  CONSTRAINT chk_appeal_status CHECK (status IN ('planned','active','completed')),
  CONSTRAINT fk_appeal_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID)
) ENGINE=InnoDB;

-- One row per gift. A gift is either cash or goods (contribution_type).
-- appealID is optional: it is empty for a general gift with no appeal.
-- The composite foreign key (appealID, organizationID) makes sure the
-- appeal belongs to the same organization that receives the gift.
-- The contribution procedures insert gifts and their detail rows atomically.
CREATE TABLE contribution (
  contributionID    INT NOT NULL AUTO_INCREMENT,
  contribution_date DATE NOT NULL,
  contribution_type ENUM('cash','goods') NOT NULL,
  donorID           INT NOT NULL,
  organizationID    INT NOT NULL,
  appealID          INT NULL,
  PRIMARY KEY (contributionID),
  UNIQUE KEY uq_contribution_type (contributionID, contribution_type),
  CONSTRAINT fk_contribution_donor FOREIGN KEY (donorID)
    REFERENCES donor (donorID),
  CONSTRAINT fk_contribution_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID),
  CONSTRAINT fk_contribution_appeal FOREIGN KEY (appealID, organizationID)
    REFERENCES appeal (appealID, organizationID)
) ENGINE=InnoDB;

-- Details of a cash contribution. One cash row per contribution, and the
-- linked contribution must have type 'cash'.
CREATE TABLE cash (
  paymentID         INT NOT NULL AUTO_INCREMENT,
  contributionID    INT NOT NULL,
  contribution_type ENUM('cash','goods') NOT NULL DEFAULT 'cash',
  amount            DECIMAL(10,2) NOT NULL,
  payment_channel   VARCHAR(50) NOT NULL,
  reference_number  VARCHAR(20) NOT NULL,
  payment_date      DATE NOT NULL,
  PRIMARY KEY (paymentID),
  UNIQUE KEY uq_cash_contribution (contributionID),
  UNIQUE KEY uq_cash_reference (reference_number),
  CONSTRAINT chk_cash_type    CHECK (contribution_type = 'cash'),
  CONSTRAINT chk_cash_amount  CHECK (amount > 0),
  CONSTRAINT chk_cash_channel CHECK (payment_channel IN ('online','offline')),
  CONSTRAINT fk_cash_contribution FOREIGN KEY (contributionID, contribution_type)
    REFERENCES contribution (contributionID, contribution_type)
) ENGINE=InnoDB;

-- Details of a goods contribution. One goods row per contribution, and
-- the linked contribution must have type 'goods'.
CREATE TABLE goods (
  goodsID           INT NOT NULL AUTO_INCREMENT,
  contributionID    INT NOT NULL,
  contribution_type ENUM('cash','goods') NOT NULL DEFAULT 'goods',
  description       VARCHAR(255) NOT NULL,
  donation_date     DATE NOT NULL,
  estimated_value   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (goodsID),
  UNIQUE KEY uq_goods_contribution (contributionID),
  CONSTRAINT chk_goods_type  CHECK (contribution_type = 'goods'),
  CONSTRAINT chk_goods_value CHECK (estimated_value >= 0),
  CONSTRAINT fk_goods_contribution FOREIGN KEY (contributionID, contribution_type)
    REFERENCES contribution (contributionID, contribution_type)
) ENGINE=InnoDB;

CREATE TABLE recipient (
  recipientID     INT NOT NULL AUTO_INCREMENT,
  recipient_name  VARCHAR(255) NOT NULL,
  address         VARCHAR(255) NOT NULL,
  email           VARCHAR(255) NOT NULL,
  phone_number    VARCHAR(20)  NOT NULL,
  applicantID     INT NOT NULL,
  PRIMARY KEY (recipientID),
  UNIQUE KEY uq_recipient_email (email),
  CONSTRAINT fk_recipient_applicant FOREIGN KEY (applicantID)
    REFERENCES applicant (applicantID)
) ENGINE=InnoDB;

-- The staff user who records a disbursement must belong to the same
-- organization that pays it out (composite foreign key on userID + organizationID).
CREATE TABLE disbursement (
  disbursementID    INT NOT NULL AUTO_INCREMENT,
  disbursement_date DATE NOT NULL,
  account_number    VARCHAR(20) NOT NULL,
  amount            DECIMAL(10,2) NOT NULL,
  organizationID    INT NOT NULL,
  recipientID       INT NOT NULL,
  userID            INT NOT NULL,
  PRIMARY KEY (disbursementID),
  CONSTRAINT chk_disbursement_amount CHECK (amount > 0),
  CONSTRAINT fk_disb_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID),
  CONSTRAINT fk_disb_recipient FOREIGN KEY (recipientID)
    REFERENCES recipient (recipientID),
  CONSTRAINT fk_disb_user_org FOREIGN KEY (userID, organizationID)
    REFERENCES `user` (userID, organizationID)
) ENGINE=InnoDB;

CREATE TABLE representative (
  representativeID    INT NOT NULL AUTO_INCREMENT,
  representative_name VARCHAR(100) NOT NULL,
  job_title           VARCHAR(50)  NOT NULL,
  email               VARCHAR(100) NOT NULL,
  address             VARCHAR(255) NOT NULL,
  phone_number        VARCHAR(20)  NOT NULL,
  userID              INT NOT NULL,
  PRIMARY KEY (representativeID),
  CONSTRAINT fk_rep_user FOREIGN KEY (userID)
    REFERENCES `user` (userID)
) ENGINE=InnoDB;

CREATE TABLE project (
  projectID      INT NOT NULL AUTO_INCREMENT,
  project_name   VARCHAR(255) NOT NULL,
  description    TEXT NOT NULL,
  start_date     DATE NOT NULL,
  end_date       DATE NOT NULL,
  budget         DECIMAL(10,2) NOT NULL,
  status         VARCHAR(50) NOT NULL,
  organizationID INT NOT NULL,
  PRIMARY KEY (projectID),
  CONSTRAINT chk_project_dates  CHECK (end_date >= start_date),
  CONSTRAINT chk_project_budget CHECK (budget >= 0),
  CONSTRAINT chk_project_status CHECK (status IN ('planned','active','completed')),
  CONSTRAINT fk_project_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID)
) ENGINE=InnoDB;

CREATE TABLE volunteer (
  volunteerID          INT NOT NULL AUTO_INCREMENT,
  volunteer_name       VARCHAR(255) NOT NULL,
  contact_number       VARCHAR(20)  NOT NULL,
  email_address        VARCHAR(255) NOT NULL,
  registered_date      DATE NOT NULL,
  availability         VARCHAR(255) NOT NULL,
  skills_and_expertise TEXT NOT NULL,
  organizationID       INT NOT NULL,
  PRIMARY KEY (volunteerID),
  CONSTRAINT fk_volunteer_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID)
) ENGINE=InnoDB;

-- Reports retain period totals; generated_at records their actual creation time.
CREATE TABLE report (
  reportID       INT NOT NULL AUTO_INCREMENT,
  report_type    ENUM('donation summary','disbursement summary','volunteer registration summary') NOT NULL,
  generated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  period_start   DATE NOT NULL,
  period_end     DATE NOT NULL,
  report_data    TEXT NOT NULL,
  organizationID INT NOT NULL,
  PRIMARY KEY (reportID),
  CONSTRAINT chk_report_period CHECK (period_end >= period_start),
  CONSTRAINT fk_report_org FOREIGN KEY (organizationID)
    REFERENCES organization (organizationID)
) ENGINE=InnoDB;

CREATE TABLE document (
  documentID    INT NOT NULL AUTO_INCREMENT,
  document_type VARCHAR(50)  NOT NULL,
  description   TEXT,
  title         VARCHAR(255) NOT NULL,
  applicantID   INT NOT NULL,
  PRIMARY KEY (documentID),
  CONSTRAINT fk_document_applicant FOREIGN KEY (applicantID)
    REFERENCES applicant (applicantID)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. VIEWS (always show CURRENT totals, calculated from the data)
-- ---------------------------------------------------------------------

-- Cash received per organization (goods are NOT counted as cash)
CREATE VIEW v_cash_by_organization AS
SELECT o.organizationID, o.name,
       COUNT(ca.paymentID)          AS cash_gifts,
       COALESCE(SUM(ca.amount), 0)  AS cash_total
FROM organization o
LEFT JOIN contribution c ON c.organizationID = o.organizationID
LEFT JOIN cash ca        ON ca.contributionID = c.contributionID
GROUP BY o.organizationID, o.name;

-- Money paid out per organization
CREATE VIEW v_disbursed_by_organization AS
SELECT o.organizationID, o.name,
       COUNT(di.disbursementID)     AS payouts,
       COALESCE(SUM(di.amount), 0)  AS total_disbursed
FROM organization o
LEFT JOIN disbursement di ON di.organizationID = o.organizationID
GROUP BY o.organizationID, o.name;

-- What each donor has given (cash and goods value shown separately)
CREATE VIEW v_donor_totals AS
SELECT d.donorID, d.name,
       COALESCE(SUM(ca.amount), 0)         AS cash_given,
       COALESCE(SUM(g.estimated_value), 0) AS goods_value
FROM donor d
LEFT JOIN contribution c ON c.donorID = d.donorID
LEFT JOIN cash  ca       ON ca.contributionID = c.contributionID
LEFT JOIN goods g        ON g.contributionID  = c.contributionID
GROUP BY d.donorID, d.name;

-- Data check for contributions without a cash or goods detail row.
CREATE VIEW v_contributions_missing_details AS
SELECT c.contributionID, c.contribution_date, c.contribution_type, c.donorID
FROM contribution c
LEFT JOIN cash  ca ON ca.contributionID = c.contributionID
LEFT JOIN goods g  ON g.contributionID  = c.contributionID
WHERE ca.paymentID IS NULL AND g.goodsID IS NULL;

-- ---------------------------------------------------------------------
-- 3. STORED PROCEDURES
-- Contribution and detail rows are saved together in one transaction.
-- ---------------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE sp_add_cash_contribution(
  IN p_date         DATE,
  IN p_donorID      INT,
  IN p_orgID        INT,
  IN p_appealID     INT,            -- use NULL for a general gift
  IN p_amount       DECIMAL(10,2),
  IN p_channel      VARCHAR(50),
  IN p_reference    VARCHAR(20),
  IN p_payment_date DATE)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO contribution (contribution_date, contribution_type, donorID, organizationID, appealID)
  VALUES (p_date, 'cash', p_donorID, p_orgID, p_appealID);
  INSERT INTO cash (contributionID, amount, payment_channel, reference_number, payment_date)
  VALUES (LAST_INSERT_ID(), p_amount, p_channel, p_reference, p_payment_date);
  COMMIT;
END$$

CREATE PROCEDURE sp_add_goods_contribution(
  IN p_date        DATE,
  IN p_donorID     INT,
  IN p_orgID       INT,
  IN p_appealID    INT,             -- use NULL for a general gift
  IN p_description VARCHAR(255),
  IN p_value       DECIMAL(10,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO contribution (contribution_date, contribution_type, donorID, organizationID, appealID)
  VALUES (p_date, 'goods', p_donorID, p_orgID, p_appealID);
  INSERT INTO goods (contributionID, description, donation_date, estimated_value)
  VALUES (LAST_INSERT_ID(), p_description, p_date, p_value);
  COMMIT;
END$$

-- Makes a period report using the records available when it is generated.
CREATE PROCEDURE sp_generate_report(
  IN p_type        VARCHAR(40),
  IN p_orgID       INT,
  IN p_start       DATE,
  IN p_end         DATE)
BEGIN
  DECLARE v_text TEXT;

  IF p_start IS NULL OR p_end IS NULL OR p_end < p_start THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid report period';
  END IF;

  IF p_type = 'donation summary' THEN
    SELECT CONCAT('Total cash received ', p_start, ' to ', p_end, ': ', COALESCE(SUM(ca.amount), 0))
      INTO v_text
    FROM contribution c
    JOIN cash ca ON ca.contributionID = c.contributionID
    WHERE c.organizationID = p_orgID AND ca.payment_date BETWEEN p_start AND p_end;
  ELSEIF p_type = 'disbursement summary' THEN
    SELECT CONCAT('Total disbursed ', p_start, ' to ', p_end, ': ', COALESCE(SUM(amount), 0))
      INTO v_text
    FROM disbursement
    WHERE organizationID = p_orgID AND disbursement_date BETWEEN p_start AND p_end;
  ELSEIF p_type = 'volunteer registration summary' THEN
    SELECT CONCAT('Volunteers registered ', p_start, ' to ', p_end, ': ', COUNT(*))
      INTO v_text
    FROM volunteer
    WHERE organizationID = p_orgID AND registered_date BETWEEN p_start AND p_end;
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown report type';
  END IF;

  INSERT INTO report (report_type, period_start, period_end, report_data, organizationID)
  VALUES (p_type, p_start, p_end, v_text, p_orgID);
END$$

DELIMITER ;

-- Application role for contribution entry through the transaction procedures.
CREATE ROLE IF NOT EXISTS rangsit_aid_contributor;
GRANT EXECUTE ON PROCEDURE rangsit_aid.sp_add_cash_contribution TO rangsit_aid_contributor;
GRANT EXECUTE ON PROCEDURE rangsit_aid.sp_add_goods_contribution TO rangsit_aid_contributor;

-- ---------------------------------------------------------------------
-- 4. SAMPLE DATA (fictional)
-- ---------------------------------------------------------------------

INSERT INTO organization (organizationID, name, address, email, phone_number) VALUES
(1, 'Charity Foundation',       '123 Main Street',   'charity@email.com',      '(555) 555-5555'),
(2, 'Hope Center',              '456 Elm Street',    'hope@email.com',         '(666) 666-6666'),
(3, 'Helping Hands',            '789 Oak Street',    'helpinghands@email.com', '(777) 777-7777'),
(4, 'Compassion International', '1011 Pine Street',  'compassion@email.com',   '(888) 888-8888'),
(5, 'Rescue Mission',           '1213 Maple Street', 'rescue@email.com',       '(999) 999-9999');

INSERT INTO donor (donorID, name, address, phone_number) VALUES
(1, 'John Smith',   '456 Elm Street',    '(555) 555-5555'),
(2, 'Jane Doe',     '789 Oak Street',    '(666) 666-6666'),
(3, 'Peter Jones',  '1011 Pine Street',  '(777) 777-7777'),
(4, 'Mary Brown',   '1213 Maple Street', '(888) 888-8888'),
(5, 'David Miller', '1415 Birch Street', '(999) 999-9999');

-- Fictional applicants.
INSERT INTO applicant (applicantID, full_name, address, email, phone_number, income) VALUES
(1, 'Michael Williams', '234 Elm Street',   'michael@email.com', '(111) 111-1111', 3000.00),
(2, 'Sarah Johnson',    '567 Oak Street',   'sarah@email.com',   '(222) 222-2222', 2500.00),
(3, 'David Taylor',     '890 Pine Street',  'david@email.com',   '(333) 333-3333', 1800.00),
(4, 'Emily Davis',      '123 Maple Street', 'emily@email.com',   '(444) 444-4444', 2200.00),
(5, 'Robert Jones',     '456 Birch Street', 'robert@email.com',  '(555) 555-5555', 2800.00);

-- Each staff user belongs to one organization.
INSERT INTO `user` (userID, username, passport, full_name, address, email, phone_number, organizationID) VALUES
(1, 'admin',       'A123456', 'John Doe',    '123 Main Street',  'admin@email.com',       '(555) 555-5555', 1),
(2, 'staff',       'B654321', 'Jane Smith',  '456 Elm Street',   'staff@email.com',       '(666) 666-6666', 2),
(3, 'volunteer',   'C765432', 'Peter Jones', '789 Oak Street',   'volunteer@email.com',   '(777) 777-7777', 3),
(4, 'coordinator', 'D876543', 'Emma Wilson', '1011 Pine Street', 'coordinator@email.com', '(888) 888-8888', 4);

INSERT INTO appeal (appealID, starting_date, ending_date, status, description, organizationID) VALUES
(1, '2023-10-01', '2023-10-31', 'completed', 'Winter Clothing Drive',         1),
(2, '2023-11-01', '2023-11-30', 'completed', 'Food Assistance Program',       2),
(3, '2023-12-01', '2023-12-31', 'completed', 'Holiday Toy Drive',             3),
(4, '2024-01-01', '2024-01-31', 'completed', 'Back-to-School Supplies Drive', 4),
(5, '2024-02-01', '2024-02-29', 'completed', 'Emergency Shelter Assistance',  5);

-- Contributions 4 and 5 are general gifts without an appeal.
--                                   date          donor org appeal ...
CALL sp_add_cash_contribution ('2023-10-04', 1, 1, 1,    100.00, 'online',  'ABCDEF123456',  '2023-10-04');
CALL sp_add_goods_contribution('2023-10-05', 2, 1, 1,    'Winter coats and blankets', 50.00);
CALL sp_add_cash_contribution ('2023-11-06', 3, 2, 2,    200.00, 'offline', 'RECEIPT123456', '2023-11-06');
CALL sp_add_cash_contribution ('2023-10-07', 4, 4, NULL,  75.00, 'online',  'PAYID7654321',  '2023-10-07');
CALL sp_add_goods_contribution('2023-10-08', 5, 5, NULL, 'Rice and canned food', 150.00);

INSERT INTO recipient (recipientID, recipient_name, address, email, phone_number, applicantID) VALUES
(1, 'Michael Williams', '234 Elm Street',   'michael@email.com', '(111) 111-1111', 1),
(2, 'Sarah Johnson',    '567 Oak Street',   'sarah@email.com',   '(222) 222-2222', 2),
(3, 'David Taylor',     '890 Pine Street',  'david@email.com',   '(333) 333-3333', 3),
(4, 'Emily Davis',      '123 Maple Street', 'emily@email.com',   '(444) 444-4444', 4),
(5, 'Robert Jones',     '456 Birch Street', 'robert@email.com',  '(555) 555-5555', 5);

-- Each organization pays out less than the cash it received, and the
-- staff user belongs to the paying organization.
INSERT INTO disbursement (disbursementID, disbursement_date, account_number, amount, organizationID, recipientID, userID) VALUES
(1, '2023-10-10', '123456789', 40.00, 1, 1, 1),
(2, '2023-11-12', '987654321', 60.00, 2, 2, 2),
(3, '2023-10-13', '987654321', 25.00, 4, 4, 4);

INSERT INTO representative (representativeID, representative_name, job_title, email, address, phone_number, userID) VALUES
(1, 'John Doe',     'Executive Director',     'johndoe@email.com',     '123 Main Street',   '(555) 555-5555', 1),
(2, 'Jane Smith',   'Program Manager',        'janesmith@email.com',   '456 Elm Street',    '(666) 666-6666', 2),
(3, 'Peter Jones',  'Volunteer Coordinator',  'peterjones@email.com',  '789 Oak Street',    '(777) 777-7777', 3),
(4, 'Mary Brown',   'Fundraising Specialist', 'marybrown@email.com',   '1011 Pine Street',  '(888) 888-8888', 4),
(5, 'David Miller', 'Outreach Coordinator',   'davidmiller@email.com', '1213 Maple Street', '(999) 999-9999', 1);

INSERT INTO project (projectID, project_name, description, start_date, end_date, budget, status, organizationID) VALUES
(1, 'Winter Clothing Drive',         'Collect and distribute winter clothing to those in need', '2023-10-01', '2023-11-30',  5000.00, 'completed', 1),
(2, 'Food Assistance Program',       'Provide food assistance to families and individuals struggling with hunger', '2023-11-01', '2023-12-31', 10000.00, 'completed', 2),
(3, 'Holiday Toy Drive',             'Collect and distribute toys to children in need during the holiday season', '2023-12-01', '2023-12-25',  3000.00, 'completed', 3),
(4, 'Back-to-School Supplies Drive', 'Collect and distribute school supplies to children in need', '2024-01-01', '2024-08-31',  4000.00, 'completed', 4),
(5, 'Emergency Shelter Assistance',  'Provide emergency shelter assistance to individuals and families experiencing homelessness', '2024-02-01', '2024-12-31', 15000.00, 'completed', 5);

INSERT INTO volunteer (volunteerID, volunteer_name, contact_number, email_address, registered_date, availability, skills_and_expertise, organizationID) VALUES
(1, 'John Smith',   '(555) 555-5555', 'johnsmith@email.com',   '2023-10-12', 'Weekends', 'Event planning, fundraising',             1),
(2, 'Jane Doe',     '(666) 666-6666', 'janedoe@email.com',     '2023-11-10', 'Weekdays', 'Social media management, graphic design', 2),
(3, 'Peter Jones',  '(777) 777-7777', 'peterjones@email.com',  '2023-12-10', 'Evenings', 'Data entry, administrative tasks',        3),
(4, 'Mary Brown',   '(888) 888-8888', 'marybrown@email.com',   '2024-01-10', 'Variable', 'Tutoring, mentoring',                     4),
(5, 'David Miller', '(999) 999-9999', 'davidmiller@email.com', '2024-02-10', 'On-call',  'Translation, interpretation',             5);

-- Reports for the example periods.
CALL sp_generate_report('donation summary',               1, '2023-10-01', '2023-10-31');
CALL sp_generate_report('disbursement summary',           1, '2023-10-01', '2023-10-31');
CALL sp_generate_report('volunteer registration summary', 1, '2023-10-01', '2023-10-31');
CALL sp_generate_report('donation summary',               2, '2023-11-01', '2023-11-30');
CALL sp_generate_report('disbursement summary',           2, '2023-11-01', '2023-11-30');

-- Fictional document metadata.
INSERT INTO document (documentID, document_type, description, title, applicantID) VALUES
(1, 'ID copy',       'Copy of national ID',           'ID Copy - Michael Williams',   1),
(2, 'Income proof',  'Salary slip for last 3 months', 'Income Proof - Sarah Johnson', 2),
(3, 'Address proof', 'Utility bill',                  'Address Proof - David Taylor', 3);

-- ---------------------------------------------------------------------
-- 5. EXAMPLE QUERIES
-- ---------------------------------------------------------------------

-- Q1: Current cash received per organization
SELECT name, cash_gifts, cash_total
FROM v_cash_by_organization
ORDER BY name;

-- Q2: Current money paid out per organization
SELECT name, payouts, total_disbursed
FROM v_disbursed_by_organization
ORDER BY name;

-- Q3: What each donor has given
SELECT name, cash_given, goods_value
FROM v_donor_totals
ORDER BY name;

-- Q4: Every contribution with donor, appeal and details
SELECT c.contributionID, c.contribution_date, d.name AS donor,
       COALESCE(a.description, '(general gift)') AS appeal,
       c.contribution_type, ca.amount AS cash_amount,
       g.description AS goods, g.estimated_value
FROM contribution c
JOIN donor d        ON d.donorID = c.donorID
LEFT JOIN appeal a  ON a.appealID = c.appealID
LEFT JOIN cash ca   ON ca.contributionID = c.contributionID
LEFT JOIN goods g   ON g.contributionID  = c.contributionID
ORDER BY c.contribution_date, c.contributionID;

-- Q5: Appeals open on 15 October 2023
SELECT appealID, description, status
FROM appeal
WHERE starting_date <= '2023-10-15' AND ending_date >= '2023-10-15';

-- Q6: Contributions without matching detail rows (expected result: 0 rows)
SELECT * FROM v_contributions_missing_details;
