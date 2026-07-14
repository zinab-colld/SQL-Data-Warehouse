# SQL Data Warehouse Project (Sales Data Mart)

An end-to-end Data Warehousing project built with SQL. The project demonstrates the transition of transactional data through the **Medallion Architecture (Bronze -> Silver -> Gold)**, creating a highly optimized **Star Schema (Sales Data Mart)** for reporting and analytics.

---

##  Data Model & Star Schema

We transformed our transactional tables into an analytical dimensional model leveraging a **Star Schema** to optimize query performance.

###  Database Diagram
Below is the visualization of our Star Schema designed using **dbdiagram.io**:
https://dbdiagram.io/d/6944fb444bbde0fd74c97579

<!-- تظهر الصورة تلقائياً بمجرد رفعها داخل مجلد docs باسم s
## Repository Structure

Your repository is structured as follows:

```text
├── Scripts/                  # SQL Scripts for database development
│   ├── bronze_layer.sql      # Raw tables setup
│   ├── silver_layer.sql      # Data cleansing & stored procedures
│   └── gold_layer.sql        # Star schema view creations
├── dataset/                  # Source CSV/Excel data files (if applicable)
├── docs/                     # Documentation and Schema diagram image
│   └── schema.png            # Schema visualization
└── teste/                    # Quality assurance & integrity scripts
    └── data_quality_tests.sql
