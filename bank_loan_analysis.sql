CREATE DATABASE bank_loan_db;

USE bank_loan_db;

SELECT * FROM bank_loan_data;


-- =======================================================
-- 1. KEY PERFORMANCE INDICATORS (KPIs)
-- =======================================================
-- Calculate the "Big Numbers".
SELECT 
    COUNT(id) AS Total_Loan_Applications,
    FORMAT(SUM(loan_amnt), 0) AS Total_Funded_Amount,
    FORMAT(SUM(total_pymnt), 0) AS Total_Amount_Received,
    ROUND(AVG(int_rate) * 100, 2) AS Avg_Interest_Rate,
    ROUND(AVG(dti), 2) AS Avg_DTI
FROM bank_loan_data;

-- =======================================================
-- 2. GOOD vs BAD LOAN REVIEW (Using CASE WHEN)
-- =======================================================
-- Risk Analysis: What percentage of our loans are actually paid back?
SELECT 
    CASE 
        WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN 'Good Loan'
        ELSE 'Bad Loan' 
    END AS Loan_Category,
    COUNT(id) AS Total_Loans,
    CONCAT(ROUND(COUNT(id) * 100.0 / (SELECT COUNT(*) FROM bank_loan_data), 2), '%') AS Loan_Share,
    FORMAT(SUM(loan_amnt), 0) AS Total_Funded_Amount,
    FORMAT(SUM(total_pymnt), 0) AS Total_Received_Amount
FROM bank_loan_data
GROUP BY 1;

-- =======================================================
-- 3. LOAN STATUS GRID
-- =======================================================
-- Detailed breakdown by status to see the specific default numbers.
SELECT 
    loan_status,
    COUNT(id) AS Total_Loans,
    FORMAT(SUM(total_pymnt), 0) AS Total_Amount_Received,
    FORMAT(SUM(loan_amnt), 0) AS Total_Funded_Amount,
    ROUND(AVG(int_rate * 100), 2) AS Interest_Rate
FROM bank_loan_data
GROUP BY loan_status
ORDER BY Total_Amount_Received DESC;

-- =======================================================
-- 4. MONTHLY TRENDS (Using CTE & WINDOW FUNCTIONS)
-- =======================================================
-- Shows Month-over-Month (MoM) growth in lending.
-- Uses a CTE to aggregate first, then Window Functions for calculations.
WITH Monthly_Stats AS (
    SELECT 
        MONTH(issue_date) AS Month_Num,
        MONTHNAME(issue_date) AS Month_Name,
        COUNT(id) AS Total_Loans,
        SUM(loan_amnt) AS Total_Amount
    FROM bank_loan_data
    GROUP BY MONTH(issue_date), MONTHNAME(issue_date)
)
SELECT 
    Month_Name,
    Total_Loans,
    Total_Amount,
    -- Calculate MOM Growth using LAG()
    LAG(Total_Amount, 1) OVER (ORDER BY Month_Num) AS Previous_Month_Amount,
    ROUND(
        (Total_Amount - LAG(Total_Amount, 1) OVER (ORDER BY Month_Num)) / 
        LAG(Total_Amount, 1) OVER (ORDER BY Month_Num) * 100, 
    2) AS MoM_Growth_Percentage
FROM Monthly_Stats;

-- =======================================================
-- 5. REGIONAL ANALYSIS (State Level)
-- =======================================================
-- Which states have the highest default risk?
SELECT 
    addr_state AS State,
    COUNT(id) AS Total_Loans,
    FORMAT(SUM(loan_amnt), 0) AS Total_Funded_Amount,
    -- Calculate "Bad Loan Percentage" per state
    CONCAT(ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id), 2), '%') AS Default_Rate
FROM bank_loan_data
GROUP BY addr_state
ORDER BY COUNT(id) DESC
LIMIT 10;

-- =======================================================
-- 6. TERM ANALYSIS (Long Term vs Short Term)
-- =======================================================
SELECT 
    term AS Loan_Term,
    COUNT(id) AS Total_Loans,
    CONCAT(ROUND(COUNT(id) * 100.0 / (SELECT COUNT(*) FROM bank_loan_data), 2), '%') AS Term_Share,
    CASE 
        WHEN loan_status = 'Charged Off' THEN 'Default' 
        ELSE 'Healthy' 
    END AS Status_Check
FROM bank_loan_data
GROUP BY term, Status_Check
ORDER BY term;

-- =======================================================
-- 7. ANALYSIS BY INCOME CATEGORY (Using Python-created Column)
-- =======================================================
-- Does higher income actually mean lower risk?
SELECT 
    income_category,
    COUNT(id) AS Total_Loans,
    FORMAT(AVG(annual_inc), 0) AS Avg_Income,
    FORMAT(SUM(loan_amnt), 0) AS Total_Lending,
    CONCAT(ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(id), 2), '%') AS Default_Rate
FROM bank_loan_data
GROUP BY income_category
ORDER BY AVG(annual_inc);