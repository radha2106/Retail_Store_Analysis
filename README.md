# 🖥️ TechStore — Retail Sales, Apps & Customer Analytics Dashboard

### About This Project

An end-to-end data analytics project for a retail tech store that sells devices (in-store and online) and distributes apps (Apple / Google) in the **US** and **Canada**: synthetic retail dataset generated in **Python**, load it into a relational database through a transactional relational data model with automated loading in **SQL Server**, and turned it into a multi-page report on a real interactive tool **Power BI** with custom navigation, dynamic period selection, and color-coded KPIs.

🔗 **Live Dashboard:** [HERE](https://app.powerbi.com/view?r=eyJrIjoiYzNjYmM2NWItYjJjMi00ZTZhLTg3ZmYtZjhkOGE5OTgyMDdmIiwidCI6IjQ4MjkzMjgyLTgzMmQtNGQwYi05ZTBmLTVmMmFmYTg5YTFlNCIsImMiOjJ9)

---

## 📊 What the Dashboard Shows

The report works like a small web app: a left-hand **Menu Dashboard** (Overview, Devices, Apps, US, CAN, Invoice, User) lets anyone jump between pages, and every page shares the same date slicer so numbers always line up.

| Page | What it's for |
|---|---|
| **Home / Overview** | The store-wide snapshot: total revenue, completed orders, and app revenue, each compared against last month, plus average-per-period cards. Includes an orders-status donut (completed / pending / returned), the top 5 selling device categories, app downloads per day of the week, and revenue per day of the month with the highest and lowest days highlighted. |
| **Devices** | Hardware sales in depth: in-store vs. online purchases, items returned and revenue lost to returns (split by channel), visits by day of the week, device-level ranking, and a revenue trend line. |
| **Apps** | The digital side of the business: app revenue and downloads (with last-month change and average rating), a top-7 apps-by-revenue ranking by sub-category, downloads split by Apple vs. Google, downloads by country, and a daily trend. |
| **US / CAN** | The same overview layout filtered by country, so the two markets can be compared side by side without rebuilding anything. |
| **Users (Invoice / User)** | A customer-level matrix: pick a customer (or an order status, or a month) and see each device they bought, orders completed, items returned, refunds, revenue, and a status icon for the latest order. |
| **Products** | A product matrix with a **dynamic period selector** — the viewer chooses which date grain (e.g. year, month) the columns use — plus device-category and order-status filters. |

Three **bookmarks** (`Reset_Gen`, `Reset_Dev`, `Reset_App`) give viewers a one-click way to clear their filters on the general, device, and app pages.

---

## 🧱 How It's Built — Architecture

```
Python (synthetic data)  →  CSV files  →  SQL Server (schema, stored procedures, views)  →  Power BI (report)
```

A dimension → fact design: lookup tables (calendar, device categories, app categories) feed fact tables (customers, device orders, app downloads), and SQL views pre-aggregate revenue before Power BI touches it.

### 1. Python — Data Generation (`_secure_code_viz3.ipynb`)

There's no real customer data here — the notebook builds a realistic retail dataset from scratch, one CSV per business area:

- **Calendar** — a daily calendar (2020–2025) with year, month, week, quarter, week-start/end, weekday/weekend flag, and Spanish month initials. It's the shared date backbone every table joins to.
- **Customers** — generates 50,000–80,000 customers with `Faker` (US and Spanish-language name pools), strips accents so names and emails stay clean, builds a unique `name@techstore.com` email per customer, assigns a country (US or Canada) and a signup date, then removes duplicate emails and re-numbers the IDs.
- **Device orders** — takes the device catalog and gives every device a random price inside its category's min/max price band, then generates orders: which customer bought, when, which device, how they paid (credit card / cash), whether it was in-store or online, and the order status (Completed / Pending / Returned).
- **App downloads** — the same approach for apps: each app sub-category inherits a price band from its parent category, then the script generates tens of thousands of downloads with a date, country, Apple or Google store, price, and a 1/3/5 rating.

The device catalog, device categories, app categories, and app sub-categories are fixed lookup lists (CSV files) rather than generated, since they represent the store's actual product structure. Random choices use weighted draws (`np.random.dirichlet`) so the mix isn't perfectly even — the way real sales never are.

### 2. SQL Server — Database (`viz3_fullcode.sql`)

The script rebuilds the `tech_store` database under the `ts` schema from scratch every time it runs. In plain terms:

**Dimension tables** (lookups):
- `calendar` — the date table, with a unique constraint on each date.
- `dev_catgs` / `devices` — device categories (with min/max price) and the individual items inside each one.
- `app_catgs` / `app_subcatgs` — app categories (with min/max price) and their sub-categories.

**Fact tables** (what happened):
- `full_customers` — one row per customer: name, unique email, country, and creation date.
- `full_devices` — one row per device order: customer, purchase date, in-store/online, device, price, payment type, and order status.
- `full_apps` — one row per app download: date, country, app, price, store (Apple/Google), and rating.

Foreign keys tie every fact row back to a real date, customer, device, or app — so an order can't point at a customer or product that doesn't exist.

**Stored procedures** (the automation layer — the standout part of this script):
- `ts.full_loads` — loads all eight CSVs in the right order (dimensions first, then facts) inside a **single transaction**. If any file fails, everything rolls back and the procedure prints the error message, procedure, and line number — no half-loaded database.
- `ts.reset_clean` — empties every table (children before parents) and resets the identity counters, so the whole pipeline can be re-run cleanly.

**Views** (the layer Power BI reads from):
- `vw_orders` — device revenue summed per customer, date, device, purchase channel, and order status.
- `vw_apps_downloads` — app revenue summed per date, country, app, store, and rating.

### 3. Power BI — Reporting Layer (`_measures.tmdl`)

All the business logic lives in a hidden `_measures` table (a placeholder table that only holds measures), organized into display folders by subject — `orders`, `apps`, `customers`, `others`, `buttons` — and by purpose (1. actual, 2. last month, 3. items, colors, labels, max/min points). The standout feature is a small library of **reusable DAX user-defined functions**: each piece of logic is written once and every measure that needs it just calls it.

#### The five custom functions

| Function | What it does |
|---|---|
| `udf_last_month_result(measure, option)` | Compares any measure to the previous month and returns the change with an up/down arrow. `option = 1` gives the **percentage** change (e.g. `+4.2%` with an up arrow), `option = 0` gives the **absolute** change. Returns blank in January, since there is no earlier month to compare against. |
| `udf_last_month_color(measure)` | Returns the font color for that same comparison: **green** when the measure grew, **red** when it fell, **grey** when there is nothing to compare. Cards use it for conditional formatting, so the arrow and the color always agree. |
| `udf_maxmin_point(measure)` | On a line chart, finds the highest and lowest day in the current selection and returns a highlight color only for those two points — so the best and worst days mark themselves. |
| `udf_max_label(measure)` | The bar-chart version: shows a data label only on the tallest and shortest weekday bars and leaves the rest blank, keeping the chart clean. |
| `udf_bar_label(column, measure)` | Builds the `Category | $Value` text used on the ranking bars (top categories, devices, and apps). |

#### Measure families

- **Orders and revenue** — `order_revenue` counts only *Completed* orders; `all_revenue` adds device revenue and app revenue together; `online_order_revenue` and `store_order_revenue` split device revenue by channel; `ytd_order_revenue` runs a year-to-date total (blank in January); `visits` and `all_orders` count order rows, and `all_orders_completed` counts only completed ones.
- **Returns** — `online_items_returned` / `store_item_returned` count returned orders per channel, `items_returned` adds them up, and `online_order_returned_revenue_lost` / `store_order_returned_revenue_lost` / `order_refund` sum the revenue tied to returned orders — so the Devices page can show exactly how much each channel lost to returns.
- **Apps** — `app_revenue`, `app_download` (a count of download rows), `avg_app_revenue` (revenue per download), `avg_app_download` (average downloads per app sub-category), and `app_high_rate`, which counts the 5-star downloads.
- **Customers** — `total_customers` counts customers by their *signup date* using an inactive relationship (`USERELATIONSHIP`) between the calendar and the customers table, so the date filter slices new customers without disturbing the rest of the model.
- **Averages** — `avg_revenue` and `avg_orders` are daily averages (they iterate over each date in the selection).
- **Month-over-month cards** — `lm_revenue`, `lm_orders_completed`, `lm_customer`, `lm_order_revenue`, `lm_online_order_revenue` and `lm_store_order_revenue` all call `udf_last_month_result`; every `color_*` measure (`color_all_revenue`, `color_app_download`, `color_order_store`, …) calls `udf_last_month_color`. The `last_month_*items` measures show last month's item counts for the online and in-store split.
- **Max/min and labels** — `max_min_point_all_revenue`, `max_min_point_device_revenue` and `max_min_point_apps_revenue` drive the highlighted points on the revenue lines; `max_label_app` and `max_label_device` drive the weekday bar labels; `label_devices`, `label_category` and `label_apps` build the ranking labels; and the `label_lm_*`, `label_revenue_returned` and `label_yearly_title` measures are the small text captions next to the numbers.
- **Order-status badges** — `last_status` finds each customer's most recent order (by a row-number column) and returns its status; `last_status_icon` maps that status to a small **SVG badge** generated by a measure (`complete_button` is green, `pending_button` yellow, `return_button` red) and rendered as an image inside the Users and Products tables.

On the report side, a **field parameter** (`field_selections_calendar`) lets viewers choose the date grain of the Products matrix themselves, pages are hidden in view mode and reached through the custom menu buttons, and registered SVG icons dress up the menu.

---

## 🛠️ Tech Stack

- **Python** (pandas, numpy, Faker, unidecode) — synthetic data generation
- **SQL Server (T-SQL)** — schema design, stored procedures with transactions and error handling, views
- **Power BI** — multi-page report, DAX measures and user-defined functions, field parameters, bookmarks, custom navigation

---

## 💡 Ideas for Future Enhancements

- **Cross-sell analysis** — which device categories and app categories are bought by the same customers.
- **Customer lifetime value & cohorts** — group customers by signup month and track spend over time.
- **Return-rate alerts** — flag device categories or channels whose return rate climbs above a threshold.
- **Country comparison page** — put US and CAN side by side on one page with variance indicators.
- **Forecasting** — project next month's revenue from the calendar's seasonality.
- **Automated refresh** — schedule the Python generation and `ts.full_loads` procedure so the pipeline runs without manual steps.

---

## 📁 Repo Structure

```
├── _secure_code_viz3.ipynb   # Synthetic data generation (Calendar, Customers, Device orders, App downloads)
├── viz3_fullcode.sql         # Schema, constraints, load/reset procedures, and views (SQL Server)
├── viz3_techstore.Report/    # Power BI report definition (PBIR format, readable as JSON)
├── _measures.tmdl            # DAX measures and user-defined functions (semantic model)
└── README.md
```

## ⚠️ Known Limitations

This is a portfolio/demo project, so a few things are simplified or need attention before running it end to end:
- All data is synthetic — no real customer or sales information is used.
- File paths in the notebook and the `BULK INSERT` statements point to a local folder — update them to your own environment.
- A few file and column names differ between the notebook and the SQL script (for example `full_calendar.csv` vs. `fullcalendar.csv`, `full_device.csv` vs. `fulldevices.csv`, and `apps_idx` vs. `app_idx`) and need to be aligned before loading.
- The calendar CSV contains fewer columns than the `ts.calendar` table defines, so the load needs the extra columns added to the CSV or removed from the table.
- `ts.vw_apps_downloads` joins to `ts.vw_calendar`, which isn't defined in the script — point it at `ts.calendar` or add that view.
- In the device-order cell, the filter that keeps purchases consistent with signup dates compares the two dates in the opposite direction from what its comment describes; flip it so purchases happen on or after account creation.
- The generated device-order volume is set to a small sample value in the notebook; raise it to match the scale you want.
- A few older `last_month_*` measures (for apps and for online/in-store items) still contain a hand-written copy of the month-over-month logic from before it was refactored into `udf_last_month_result`; they work, but could be rewritten to call the function and remove the duplicated code.
- Month-over-month measures return blank in January because they compare against the previous month in the same year selection.

---
