# RANGSIT Aid System Database

A relational database for an aid organization. It stores donors, cash and goods contributions, appeals, recipients, disbursements, volunteers, projects, and reports.

**University project (2024)** — Bachelor of Science in Information Technology, Rangsit University.

## About the project

I designed and implemented a database for the RANGSIT Aid System to organize aid records and support reporting. The project covers data analysis, conceptual and relational modeling, database constraints, SQL implementation, and sample queries.

## Project work

1. Analyzed the aid system and identified its main data entities.
2. Designed the conceptual and relational data models.
3. Defined primary keys, foreign keys, data types, and validation rules.
4. Implemented the database with sample data, views, stored procedures, and reporting queries.

## Repository contents

- `Rangsit_Aid_Database.sql` — complete database script, including 15 tables, 16 foreign keys, 13 `CHECK` constraints, 4 views, 3 stored procedures, sample data, and example queries.
- `ERD.md` — entity-relationship diagram showing the tables and their foreign-key connections.

The tables are `organization`, `donor`, `applicant`, `user`, `appeal`, `contribution`, `cash`, `goods`, `recipient`, `disbursement`, `representative`, `project`, `volunteer`, `report`, and `document`.

## Data rules and reporting

- A contribution belongs to one donor and one organization. An optional appeal must belong to that same organization.
- Cash and goods details are stored separately. Their foreign keys and constraints require each detail row to match the contribution type.
- `sp_add_cash_contribution` and `sp_add_goods_contribution` save each contribution and its detail row in one transaction. `v_contributions_missing_details` identifies contributions with no matching detail row.
- A disbursement must be recorded by a staff user from the organization making the payment.
- The three summary views show current cash, disbursement, and donor totals. `sp_generate_report` saves a period-specific snapshot for cash received, disbursements, or volunteer registrations.
- The `rangsit_aid_contributor` role has permission to execute the two contribution procedures. It is not assigned to a database user by the script.

## How to run

The script was tested with MySQL 8.0.46 and MariaDB 10.11. Run it once using an account that can create a database and role:

```bash
mysql -u root -p < Rangsit_Aid_Database.sql
```

It creates the `rangsit_aid` database and loads fictional sample data. It does not delete an existing database. If `rangsit_aid` already exists, the script stops at the `CREATE DATABASE` statement.

## Example queries

```sql
USE rangsit_aid;

SELECT * FROM v_cash_by_organization;
SELECT * FROM v_donor_totals;
SELECT * FROM v_contributions_missing_details;
```

Example cash contribution, using the sample donor, organization, and appeal IDs:

```sql
CALL sp_add_cash_contribution(
  '2023-10-20', 2, 1, 1, 30.00, 'online', 'REF0001', '2023-10-20'
);
```

## Tools

SQL, MySQL, MariaDB, stored procedures, views, and entity-relationship diagrams.

## Author

Nyi Nyein Zin
