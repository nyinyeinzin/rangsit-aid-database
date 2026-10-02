# RANGSIT Aid System — Entity Relationship Diagram

```mermaid
erDiagram
    organization {
        INT organizationID PK
        VARCHAR name
        VARCHAR address
        VARCHAR email UK
        VARCHAR phone_number
    }
    donor {
        INT donorID PK
        VARCHAR name
        VARCHAR address
        VARCHAR phone_number
    }
    applicant {
        INT applicantID PK
        VARCHAR full_name
        VARCHAR address
        VARCHAR email
        VARCHAR phone_number
        DECIMAL income
    }
    user {
        INT userID PK
        VARCHAR username UK
        VARCHAR passport
        VARCHAR full_name
        VARCHAR address
        VARCHAR email
        VARCHAR phone_number
        INT organizationID FK
    }
    appeal {
        INT appealID PK
        DATE starting_date
        DATE ending_date
        VARCHAR status
        TEXT description
        INT organizationID FK
    }
    contribution {
        INT contributionID PK
        DATE contribution_date
        ENUM contribution_type
        INT donorID FK
        INT organizationID FK
        INT appealID FK
    }
    cash {
        INT paymentID PK
        INT contributionID FK,UK
        ENUM contribution_type FK
        DECIMAL amount
        VARCHAR payment_channel
        VARCHAR reference_number UK
        DATE payment_date
    }
    goods {
        INT goodsID PK
        INT contributionID FK,UK
        ENUM contribution_type FK
        VARCHAR description
        DATE donation_date
        DECIMAL estimated_value
    }
    recipient {
        INT recipientID PK
        VARCHAR recipient_name
        VARCHAR address
        VARCHAR email UK
        VARCHAR phone_number
        INT applicantID FK
    }
    disbursement {
        INT disbursementID PK
        DATE disbursement_date
        VARCHAR account_number
        DECIMAL amount
        INT organizationID FK
        INT recipientID FK
        INT userID FK
    }
    representative {
        INT representativeID PK
        VARCHAR representative_name
        VARCHAR job_title
        VARCHAR email
        VARCHAR address
        VARCHAR phone_number
        INT userID FK
    }
    project {
        INT projectID PK
        VARCHAR project_name
        TEXT description
        DATE start_date
        DATE end_date
        DECIMAL budget
        VARCHAR status
        INT organizationID FK
    }
    volunteer {
        INT volunteerID PK
        VARCHAR volunteer_name
        VARCHAR contact_number
        VARCHAR email_address
        DATE registered_date
        VARCHAR availability
        TEXT skills_and_expertise
        INT organizationID FK
    }
    report {
        INT reportID PK
        ENUM report_type
        TIMESTAMP generated_at
        DATE period_start
        DATE period_end
        TEXT report_data
        INT organizationID FK
    }
    document {
        INT documentID PK
        VARCHAR document_type
        TEXT description
        VARCHAR title
        INT applicantID FK
    }

    organization o|--o{ user : employs
    organization ||--o{ appeal : runs
    donor ||--o{ contribution : makes
    organization ||--o{ contribution : receives
    appeal o|--o{ contribution : receives
    contribution ||--o| cash : cash_detail
    contribution ||--o| goods : goods_detail
    applicant ||--o{ recipient : becomes
    organization ||--o{ disbursement : pays
    recipient ||--o{ disbursement : receives
    user ||--o{ disbursement : records
    user ||--o{ representative : has
    organization ||--o{ project : runs
    organization ||--o{ volunteer : registers
    organization ||--o{ report : generates
    applicant ||--o{ document : provides
```

`appealID` on `contribution` and `organizationID` on `user` are optional. The contribution-to-appeal and disbursement-to-user relationships use composite foreign keys with `organizationID`; cash and goods use composite foreign keys with `contribution_type`. A contribution is recorded as either cash or goods through the matching stored procedure.
