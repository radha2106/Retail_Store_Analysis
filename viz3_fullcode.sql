USE master;
IF EXISTS (SELECT * FROM sys.databases WHERE name='tech_store')
BEGIN
    DROP DATABASE tech_store
END
GO
    CREATE DATABASE tech_store
GO
    USE tech_store
GO
    CREATE SCHEMA ts
GO
PRINT('Database "Tech_Store" recreated; schemas "ts" recreated')

IF OBJECT_ID ('ts.calendar','U') IS NOT NULL
	DROP TABLE ts.calendar;
		CREATE TABLE ts.calendar(
			idx BIGINT IDENTITY (1,1) NOT NULL,
			dates DATE NOT NULL,
			years INT NOT NULL,
			months INT NOT NULL,
			months_names VARCHAR(3) NOT NULL,
			days INT NOT NULL,
			days_week INT NOT NULL,
			days_name VARCHAR(3) NOT NULL,
			months_ends DATE NOT NULL,
			quarters INT NOT NULL,
			week_start DATE NOT NULL,
			week_end DATE NOT NULL,
			weeks VARCHAR(7) NOT NULL,
			week_year INT NOT NULL,
			ini_month VARCHAR(1) NOT NULL,
			max_year INT NOT NULL,
			max_month INT NOT NULL,
			max_week DATE NOT NULL
);
PRINT('>> Calendar Table created')

IF OBJECT_ID ('ts.devices','U') IS NOT NULL
	DROP TABLE ts.devices;
		CREATE TABLE ts.devices(
			idx BIGINT IDENTITY (1,1) NOT NULL,
			item_name VARCHAR(100) NOT NULL,
			dev_idx BIGINT NOT NULL
);
PRINT('>> Devices Table created')

IF OBJECT_ID ('ts.dev_catgs','U') IS NOT NULL
	DROP TABLE ts.dev_catgs;
		CREATE TABLE ts.dev_catgs(
			idx BIGINT IDENTITY (1,1) NOT NULL,
			category VARCHAR(100) NOT NULL,
			min_price INT NOT NULL,
			max_price INT NOT NULL
);
PRINT('>> Device Categories Table created')

IF OBJECT_ID ('ts.app_subcatgs','U') IS NOT NULL
	DROP TABLE ts.app_subcatgs;
		CREATE TABLE ts.app_subcatgs(
			idx BIGINT IDENTITY (1,1) NOT NULL,
			app_subcatg_name VARCHAR(100) NOT NULL,
			app_idx BIGINT NOT NULL
);
PRINT('>> App Sub-categories Table created')

IF OBJECT_ID ('ts.app_catgs','U') IS NOT NULL
	DROP TABLE ts.app_catgs;
		CREATE TABLE ts.app_catgs(
			idx BIGINT IDENTITY (1,1) NOT NULL,
			apps_name VARCHAR(100) NOT NULL,
			min_price INT NOT NULL,
			max_price INT NOT NULL
);
PRINT('>> App Categories Table created')

IF OBJECT_ID ('ts.full_customers','U') IS NOT NULL
	DROP TABLE ts.full_customers;
		CREATE TABLE ts.full_customers(
			idx BIGINT IDENTITY (1,1) NOT NULL,
			customer_fullname VARCHAR(100) NOT NULL,
			customer_email VARCHAR(100) NOT NULL,
			customer_country VARCHAR(5) NOT NULL,
			created_on BIGINT NOT NULL
);
PRINT('>> App Customers Table created')

IF OBJECT_ID ('ts.full_apps','U') IS NOT NULL
	DROP TABLE ts.full_apps;
		CREATE TABLE ts.full_apps(
			download_on BIGINT NOT NULL,
			country VARCHAR(10) NOT NULL,
			app_idx BIGINT NOT NULL,
			app_price DECIMAL(4,2) NOT NULL,
			app_dev VARCHAR(10) NOT NULL,
			app_rate INT NOT NULL
);
PRINT('>> Full Raw Apps Table created')

IF OBJECT_ID ('ts.full_devices','U') IS NOT NULL
	DROP TABLE ts.full_devices;
		CREATE TABLE ts.full_devices(
			customer_idx BIGINT NOT NULL,
			bougth_on BIGINT NOT NULL,
			bougth_as VARCHAR(20) NOT NULL,
			device_idx BIGINT NOT NULL,
			device_price DECIMAL(7,2) NOT NULL,
			device_pay VARCHAR(20) NOT NULL,
			order_status VARCHAR(20) NOT NULL
);
PRINT('>> Full Devices Table created')
-----------------------------------------------------------------
--Primary/Foreing Keys and constraints
	--Calendar
ALTER TABLE ts.calendar
ADD CONSTRAINT PK_dates PRIMARY KEY (idx,dates),
	CONSTRAINT UQ_dates UNIQUE (dates)
PRINT('--ts.calendar constraints re-created')
-----------------------------
	--App Category
ALTER TABLE ts.app_catgs
ADD CONSTRAINT PK_appcatg PRIMARY KEY (idx),
	CONSTRAINT UQ_appname UNIQUE (apps_name)
PRINT('--ts.app_catgs constraints re-created')
-----------------------------
	--App Subcategory
ALTER TABLE ts.app_subcatgs
ADD CONSTRAINT PK_appsubcatg PRIMARY KEY (idx),
	CONSTRAINT UQ_appsubcatgname UNIQUE (app_subcatg_name),
	CONSTRAINT FK_app_catg FOREIGN KEY (app_idx) REFERENCES ts.app_catgs (idx)
PRINT('--ts.app_subcatgs constraints re-created')
-----------------------------
	--Device Category
ALTER TABLE ts.dev_catgs
ADD CONSTRAINT PK_devcatg PRIMARY KEY(idx),
	CONSTRAINT UQ_devcatg UNIQUE (category)
PRINT('--ts.dev_catgs constraints re-created')
-----------------------------
	--Devices
ALTER TABLE ts.devices
ADD CONSTRAINT PK_dev PRIMARY KEY(idx),
	CONSTRAINT UQ_dev UNIQUE (item_name),
	CONSTRAINT FK_devcatg FOREIGN KEY (dev_idx) REFERENCES ts.dev_catgs (idx)
PRINT('--ts.devices constraints re-created')

-----------------------------
	--Full Devices
ALTER TABLE ts.full_devices
	ADD CONSTRAINT FK_customer FOREIGN KEY (customer_idx) REFERENCES ts.full_customers (idx),
	CONSTRAINT FK_bougthon FOREIGN KEY (bougth_on) REFERENCES ts.calendar (idx),
	CONSTRAINT FK_deviceidx FOREIGN KEY (device_idx) REFERENCES ts.devices (idx)
PRINT('--ts.full_devices constraints re-created')
-----------------------------
	--Customers
ALTER TABLE ts.full_customers
ADD CONSTRAINT PK_cust PRIMARY KEY (idx),
	CONSTRAINT UQ_email UNIQUE (customer_email),
	CONSTRAINT FK_createdon FOREIGN KEY (created_on) REFERENCES ts.calendar (idx)
PRINT('--ts.full_customers constraints re-created')

-----------------------------
	--Full Apps
ALTER TABLE ts.full_apps
	ADD CONSTRAINT FK_downloadon FOREIGN KEY (download_on) REFERENCES ts.calendar (idx),
	CONSTRAINT FK_appidx FOREIGN KEY (app_idx) REFERENCES ts.app_subcatgs (idx)
PRINT('--ts.full_devices constraints re-created')
-----------------------------------------------------------------
CREATE OR ALTER PROCEDURE ts.full_loads AS
BEGIN
-- SET XACT_ABORT ON instructs SQL Server to roll back 
-- the entire transaction immediately if a run-time error occurs.
    SET XACT_ABORT ON;
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        PRINT ('===Loading Dimensions Tables====')
        DECLARE @total_rows INT, @start DATETIME = GETDATE(), @end DATETIME = GETDATE();

-- Devices
        BULK INSERT ts.devices
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\devices.csv'
        WITH (FIRSTROW=2,FIELDTERMINATOR=',',TABLOCK);

        SELECT @total_rows = COUNT(*) FROM ts.devices;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.devices table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

-- Device Categories
        BULK INSERT ts.dev_catgs
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\dev_catgs.csv'
        WITH (FIRSTROW=2,FIELDTERMINATOR=',',TABLOCK);

        SELECT @total_rows = COUNT(*) FROM ts.dev_catgs;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.dev_catgs table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

-- App Subcategories
        BULK INSERT ts.app_subcatgs
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\app_subcatgs.csv'
        WITH (FIRSTROW=2,FIELDTERMINATOR=',',TABLOCK);

        SELECT @total_rows = COUNT(*) FROM ts.app_subcatgs;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.app_subcatgs table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

-- App Categories
        BULK INSERT ts.app_catgs
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\app_catgs.csv'
        WITH (FIRSTROW=2, FIELDTERMINATOR=',', TABLOCK);
        
        SELECT @total_rows = COUNT(*) FROM ts.app_catgs;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.app_catgs table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

-- Calendar
        BULK INSERT ts.calendar
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\fullcalendar.csv'
        WITH (FIRSTROW=2, FIELDTERMINATOR=',', TABLOCK);
        
        SELECT @total_rows = COUNT(*) FROM ts.calendar;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.calendar table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

-- Customers
        BULK INSERT ts.full_customers
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\fullcustomers.csv'
        WITH (FIRSTROW=2,FIELDTERMINATOR=',',TABLOCK);

        SELECT @total_rows = COUNT(*) FROM ts.full_customers;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.full_customers table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

-- Full Devices
        BULK INSERT ts.full_devices
        FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\fulldevices.csv'
        WITH (FIRSTROW=2, FIELDTERMINATOR=',', TABLOCK);
        
        SELECT @total_rows = COUNT(*) FROM ts.full_devices;
        PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.full_devices table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading'
        PRINT '=========='

-- Full App File
	    BULK INSERT ts.full_apps
	    FROM 'C:\Users\USER\Desktop\DA_Portfolio\viz3_techstore\viz3_csv\fullapps.csv'
	    WITH (FIRSTROW=2,FIELDTERMINATOR=',',TABLOCK);

	    SELECT @total_rows = COUNT(*) FROM ts.full_apps;
	    PRINT CAST(@total_rows AS VARCHAR(max))+' rows re-loaded on ts.full_apps table';
        PRINT CAST(DATEDIFF(second,@start,@end) AS VARCHAR(max))+' seconds for loading';
        PRINT '=========='

        -- If we reached here without errors, save all changes forever
        COMMIT TRANSACTION;
        PRINT ('----All Tables Loaded Successfully----');

    END TRY
    BEGIN CATCH
        -- If an error happens, check if there is an active transaction to roll back
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;

        -- Print detailed error info
        PRINT '!!! ERROR DETECTED - ALL CHANGES ROLLED BACK !!!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        END;
    END CATCH
END
-------------------------------------------------
exec ts.full_loads
---------------------------------------------------
CREATE PROCEDURE ts.reset_clean
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Delete data from tables
            -- Note: Ensure Child tables are deleted before Parent tables
            TRUNCATE TABLE ts.full_devices;
            TRUNCATE TABLE ts.full_apps;
            TRUNCATE TABLE ts.full_customers;
            TRUNCATE TABLE ts.calendar;
            TRUNCATE TABLE ts.devices;
            TRUNCATE TABLE ts.dev_catgs;
            TRUNCATE TABLE ts.app_subcatgs;
            TRUNCATE TABLE ts.app_catgs;

            -- Reset Identities Counts
            DBCC CHECKIDENT ('ts.full_devices', RESEED, 0);
            DBCC CHECKIDENT ('ts.full_customers', RESEED, 0);
            DBCC CHECKIDENT ('ts.calendar', RESEED, 0);
            DBCC CHECKIDENT ('ts.devices', RESEED, 0);
            DBCC CHECKIDENT ('ts.dev_catgs', RESEED, 0);
            DBCC CHECKIDENT ('ts.app_subcatgs', RESEED, 0);
            DBCC CHECKIDENT ('ts.app_catgs', RESEED, 0);

        COMMIT TRANSACTION;
        PRINT 'All clean tables cleared and identities reset successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
---------------------------------------------------
--View Tables
CREATE OR ALTER VIEW ts.vw_apps_downloads AS(
SELECT download_on,country,app_idx,SUM(app_price) AS app_revenue,
app_dev,
app_rate
FROM ts.full_apps AS fa
INNER JOIN ts.vw_calendar AS cal
ON fa.download_on = cal.idx
GROUP BY download_on,country,app_idx,app_dev,app_rate)

CREATE OR ALTER VIEW ts.vw_orders AS(
SELECT customer_idx,bougth_on,device_idx,bougth_as, SUM(device_price) AS total_revenue,order_status
FROM ts.full_devices AS fd
INNER JOIN ts.calendar AS cal
ON fd.bougth_on = cal.idx
GROUP BY bougth_on,bougth_as,device_idx,customer_idx,order_status)