-- 1.Overall Churn Overview
-- Core KPIs:Total Customers,Churned Customers,Churn Rate,Stayed Customers,Joined Customers,Total Revenue,Revenue from Churned Customers,Churn Revenue Share,Net Customer Growth
SELECT 
	COUNT(*) AS total_customers,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
		 SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)
         / COUNT(*),
         4
	 ) AS churn_rate,
     SUM(CASE WHEN Customer_Status = 'Stayed' THEN 1 ELSE 0 END) AS stayed_customers,
     SUM(CASE WHEN Customer_Status = 'Joined' THEN 1 ELSE 0 END) AS joined_customers,
     ROUND(SUM(Total_Revenue),2) AS total_revenue,
     ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN Total_Revenue ELSE 0 END),2) AS revenue_from_churned_customers,
     ROUND(
		SUM(CASE WHEN Customer_Status = 'Churned' THEN Total_Revenue ELSE 0 END)
        / SUM(Total_Revenue),
        4
	 ) AS Churn_Revenue_Share,
     SUM(CASE WHEN Customer_Status = 'Joined' THEN 1 ELSE 0 END)
     -
     SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS net_growth
FROM telecom_customer_churn;

-- 2.WHO is Churning
-- 2.1 Tenure Analysis: Are new customers more likely to churn?
SELECT
	CASE
		WHEN Tenure_in_Months < 6 THEN '0-6 months'
        WHEN Tenure_in_Months < 12 THEN '6-12 months'
        WHEN Tenure_in_Months < 24 THEN '12-24 months'
        ELSE '24+ months'
	END AS tenure_group,
    COUNT(*) AS total_users,
    SUM(CASE WHEN  Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned_users,
    ROUND(
		SUM(CASE WHEN  Customer_Status = 'Churned' THEN 1 ELSE 0 END)
        /COUNT(*)
	,3) AS churn_rate
FROM telecom_customer_churn
WHERE Monthly_Charge >= 0
GROUP BY tenure_group
ORDER BY churn_rate DESC;

-- 2.2 Contract Analysis: Do contract types impact churn?
SELECT
	Contract,
    COUNT(*) AS total_users,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)AS churned_users,
    ROUND(
		SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)
        /COUNT(*)
	,3) AS churn_rate
FROM telecom_customer_churn
WHERE Monthly_Charge >= 0
GROUP BY Contract
ORDER BY churn_rate DESC;

-- 2.3 Pricing Analysis: Monthly Charge
WITH charge_base AS (
	SELECT
		Customer_Status,
		Monthly_Charge,
    NTILE(3) over (ORDER BY Monthly_Charge) AS charge_group_id
	FROM telecom_customer_churn
    WHERE Monthly_Charge >= 0
)
SELECT
	CASE charge_group_id
    WHEN 1 THEN 'Low'
    WHEN 2 THEN 'Medium'
    ELSE 'High'
    END AS charge_group,
    COUNT(*) AS total_user,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned_users,
    ROUND(
		SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)
        /COUNT(*),
	2) AS churn_rate
FROM charge_base
GROUP BY charge_group_id
ORDER BY charge_group_id;

-- 3.Where is Churn Concentrated? Cross-Segement Analysis
-- 3.1 Cross：Tenure × Contract
SELECT
	Contract,
    CASE 
		WHEN Tenure_in_Months < 6 THEN '0-6 months'
        WHEN Tenure_in_Months < 12 THEN '6-12 months'
		WHEN Tenure_in_Months < 24 THEN '12-24 months'
        ELSE '24+ months'
	END AS tenure_group,
    COUNT(*) AS total_users,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned_users,
    ROUND(
		SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)
        /COUNT(*)
	,2) AS churn_rate
FROM telecom_customer_churn
GROUP BY Contract,tenure_group
ORDER BY churn_rate DESC;


-- 3.2 Cross：Contract × Monthly Charge
WITH charge_base AS (
	SELECT
		Contract,
        Customer_Status,
        NTILE(3) OVER (ORDER BY Monthly_Charge) AS charge_group_id
	FROM telecom_customer_churn
    WHERE Monthly_Charge >= 0
)
SELECT
	Contract,
    CASE charge_group_id
    WHEN 1 THEN 'Low'
    WHEN 2 THEN 'Medium'
    ELSE 'High'
    END AS charge_group,
    COUNT(*) AS total_users,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned_users,
    ROUND(
		SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END)
        /COUNT(*),
	2) AS churn_rate
FROM charge_base
GROUP BY Contract,charge_group_id
ORDER BY churn_rate DESC;

-- 3.3 Cross Analysis: Monthly Charge × Tenure
WITH base AS (
    SELECT
        CASE 
            WHEN Tenure_in_Months < 6 THEN '0-6 months'
            WHEN Tenure_in_Months < 12 THEN '6-12 months'
            WHEN Tenure_in_Months < 24 THEN '12-24 months'
            ELSE '24+ months'
        END AS tenure_group,
        NTILE(3) OVER (ORDER BY Monthly_Charge) AS charge_group_id,
        Customer_Status
    FROM telecom_customer_churn
    WHERE Monthly_Charge >= 0
)

SELECT
    tenure_group,
    CASE charge_group_id
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        ELSE 'High'
    END AS charge_group,
    COUNT(*) AS total_users,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS churned_users,
    ROUND(
        SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
        3
    ) AS churn_rate
FROM base
GROUP BY tenure_group, charge_group
ORDER BY 
  CASE tenure_group
    WHEN '0-6 months' THEN 1
    WHEN '6-12 months' THEN 2
    WHEN '12-24 months' THEN 3
    WHEN '24+ months' THEN 4
  END,
  CASE charge_group
    WHEN 'Low' THEN 1
    WHEN 'Medium' THEN 2
    WHEN 'High' THEN 3
  END DESC;
  
  -- 4. Why Are High-Risk Customers Churning? Cause Analysis
  -- 4.1 Churn Category Analysis: High-Risk Segment vs Other Customers
WITH base AS (
	SELECT
		Customer_ID,
        Customer_Status,
        Churn_Category,
        Contract,
        CASE
			WHEN Tenure_in_Months < 6 THEN '0-6 months'
            WHEN Tenure_in_Months < 12 THEN '6-12 months'
            WHEN Tenure_in_Months < 24 THEN '12-24 months'
            ELSE '24+ months'
		END AS tenure_group,
        NTILE(3) OVER (ORDER BY Monthly_Charge) AS charge_group_id
	FROM telecom_customer_churn
    WHERE Monthly_Charge >= 0
)
SELECT
	CASE
		WHEN tenure_group = '0-6 months'
        AND Contract = 'Month-to-Month'
        AND charge_group_id = 3
	THEN 'High Risk Segment'
    ELSE 'Other Customers'
	END AS customer_segment,
	Churn_Category,
    COUNT(*) AS churned_customers,
    ROUND(
		COUNT(*)
        / SUM(COUNT(*)) OVER (
			PARTITION BY
            CASE
				WHEN tenure_group = '0-6 months'
				AND Contract = 'Month-to-Month'
				AND charge_group_id = 3
			THEN 'High Risk Segment'
			ELSE 'Other Customers'
		END 
        )
        ,2) AS category_percentage
FROM base
WHERE Customer_Status = 'Churned'
GROUP BY customer_segment, Churn_Category
ORDER BY customer_segment, category_percentage DESC;


-- 4.2 Churn Reason Analysis: High-Risk Segment vs Other Customers
WITH base AS (
    SELECT
        Customer_ID,
        Customer_Status,
        Churn_Reason,
        Contract,
        CASE
            WHEN Tenure_in_Months < 6 THEN '0-6 months'
            WHEN Tenure_in_Months < 12 THEN '6-12 months'
            WHEN Tenure_in_Months < 24 THEN '12-24 months'
            ELSE '24+ months'
        END AS tenure_group,
        NTILE(3) OVER (ORDER BY Monthly_Charge) AS charge_group_id
    FROM telecom_customer_churn
    WHERE Monthly_Charge >= 0
),

segment AS (
    SELECT
        Customer_ID,
        Customer_Status,
        Churn_Reason,
        CASE
            WHEN tenure_group = '0-6 months'
                 AND Contract = 'Month-to-onth'
                 AND charge_group_id = 3
            THEN 'High Risk Segment'
            ELSE 'Other Customers'
        END AS customer_segment
    FROM base
),

reason_counts AS (
    SELECT
        customer_segment,
        Churn_Reason,
        COUNT(*) AS churned_customers
    FROM segment
    WHERE Customer_Status = 'Churned'
    GROUP BY customer_segment, Churn_Reason
)

SELECT
    customer_segment,
    Churn_Reason,
    churned_customers,
    ROUND(
        churned_customers * 100.0 /
        SUM(churned_customers) OVER (PARTITION BY customer_segment),
        2
    ) AS reason_percentage
FROM reason_counts
ORDER BY customer_segment, reason_percentage DESC;    
    
            
-- 5.Business Impact Analysis
-- 5.1 Contract Impact Analysis
SELECT
    Contract,
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN Customer_Status = 'Churned'
            THEN 1
            ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        SUM(
            CASE
                WHEN Customer_Status = 'Churned'
                THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        ,3
    ) AS churn_rate,

    ROUND(
        SUM(
            CASE
                WHEN Customer_Status = 'Churned'
                THEN Total_Revenue
                ELSE 0
            END
        )
        ,0
    ) AS churned_revenue,

    ROUND(
        AVG(
            CASE
                WHEN Customer_Status = 'Churned'
                THEN Total_Revenue
            END
        )
        ,0
    ) AS avg_churned_customer_revenue

FROM telecom_customer_churn
WHERE Monthly_Charge >= 0
GROUP BY Contract
ORDER BY churned_revenue DESC;

-- 6.Operational Segment Trigger Analysis
-- 6.1 Churn Reason Analysis by Contract Type
SELECT
    Contract,
    Churn_Reason,
    COUNT(*) AS churned_customers,
    ROUND(
        COUNT(*) /
        SUM(COUNT(*)) OVER (PARTITION BY Contract)
        ,2
    ) AS reason_percentage
FROM telecom_customer_churn
WHERE Customer_Status = 'Churned'
GROUP BY Contract, Churn_Reason
ORDER BY Contract, reason_percentage DESC;
	


