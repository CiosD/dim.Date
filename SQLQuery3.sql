BEGIN TRY
	DROP TABLE [dbo].[DimDate]
END TRY

BEGIN CATCH
	/*No Action*/
END CATCH

/**********************************************************************************/

CREATE TABLE [dbo].[DimDate]
	(	[date_key] INT primary key, 
		[Date] date not Null,
		[DateName] char(11),
		[DateNameUS1] CHAR(11),-- Date in MM-dd-yyyy format
		[DateNameUS2] CHAR(11),-- Date in MM-dd-yyyy format
		[DateNameEU] CHAR(11), -- Date in dd-MM-yyyy format
		[DateNameCustom1] VARCHAR(45),
		[DayOfWeek] CHAR(1),-- First Day Sunday=1 and Saturday=7
		[DayNameOfWeek] VARCHAR(9), -- Contains name of the day, Sunday, Monday 
		[DayOfMonth] VARCHAR(2), -- Field will hold day number of Month
		[DayOfYear] VARCHAR(3),
		[WeekdayWeekend] char(10),-- 0=Week End ,1=Week Day,
		[WeekOfYear] VARCHAR(2),--Week Number of the Year
		[MonthName] VARCHAR(9),--January, February etc
		[MonthNameShort] varchar(3),
		[MonthOfYear] VARCHAR(2), --Number of the Month 1 to 12
		[IsFirstDayOfMonth] CHAR(1),
		[IsLastDayOfMonth] CHAR(1),
		[Quarter] CHAR(1),
		[Year] CHAR(4),-- Year value of Date stored in Row
		[YearWeek] CHAR(10), --CY 2012,CY 2013
		[Year-Month] CHAR(10), --Jan-2013,Feb-2013
		[YearMonth] CHAR(10),
		[YearQuarter] CHAR(10),
	)
GO


/********************************************************************************************/
--Specify Start Date and End date here
--Value of Start Date Must be Less than Your End Date 

DECLARE @StartDate DATETIME = '03/01/2021' --Starting value of Date Range
DECLARE @EndDate DATETIME = '01/01/2023' --End Value of Date Range

--Temporary Variables To Hold the Values During Processing of Each Date of Year
DECLARE
	@DayOfWeekInMonth INT,
	@DayOfWeekInYear INT,
	@DayOfQuarter INT,
	@WeekOfMonth INT,
	@CurrentYear INT,
	@CurrentMonth INT,
	@CurrentQuarter INT

/*Table Data type to store the day of week count for the month and year*/
DECLARE @DayOfWeek TABLE (DOW INT, MonthCount INT, QuarterCount INT, YearCount INT)

INSERT INTO @DayOfWeek VALUES (1, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (2, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (3, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (4, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (5, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (6, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (7, 0, 0, 0)

--Extract and assign various parts of Values from Current Date to Variable

DECLARE @CurrentDate AS DATETIME = @StartDate
SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

/********************************************************************************************/
--Proceed only if Start Date(Current date ) is less than End date you specified above

WHILE @CurrentDate < @EndDate
BEGIN
 
/*Begin day of week logic*/

         /*Check for Change in Month of the Current date if Month changed then 
          Change variable value*/
	IF @CurrentMonth != DATEPART(MM, @CurrentDate) 
	BEGIN
		UPDATE @DayOfWeek
		SET MonthCount = 0
		SET @CurrentMonth = DATEPART(MM, @CurrentDate)
	END

        /* Check for Change in Quarter of the Current date if Quarter changed then change 
         Variable value*/

	IF @CurrentQuarter != DATEPART(QQ, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET QuarterCount = 0
		SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)
	END
       
        /* Check for Change in Year of the Current date if Year changed then change 
         Variable value*/
	

	IF @CurrentYear != DATEPART(YY, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET YearCount = 0
		SET @CurrentYear = DATEPART(YY, @CurrentDate)
	END
	
        -- Set values in table data type created above from variables 

	UPDATE @DayOfWeek
	SET 
		MonthCount = MonthCount + 1,
		QuarterCount = QuarterCount + 1,
		YearCount = YearCount + 1
	WHERE DOW = DATEPART(DW, @CurrentDate)

	SELECT
		@DayOfWeekInMonth = MonthCount,
		@DayOfQuarter = QuarterCount,
		@DayOfWeekInYear = YearCount
	FROM @DayOfWeek
	WHERE DOW = DATEPART(DW, @CurrentDate)
	
/*End day of week logic*/


/* Populate Your Dimension Table with values*/
	
	INSERT INTO [dbo].[DimDate]
	SELECT
		
		CONVERT (char(8),@CurrentDate,112) as date_key,
		@CurrentDate AS Date,
		CONVERT (char(11),@CurrentDate,111) as DateName,
		CONVERT (char(11),@CurrentDate,101) as DateNameUS1,
		FORMAT (@CurrentDate, 'M/d/yyyy') as DateNameUS2,
		CONVERT (char(11),@CurrentDate,103) as DateNameEU,
		CONVERT(VARCHAR(9), DATENAME(DW, @CurrentDate)) + ', ' +
		(CONVERT(varchar(45), @CurrentDate, 107)) AS DateNameCustom1,
		DATEPART(DW, @CurrentDate) AS DayOfWeek,
		DATENAME(DW, @CurrentDate) AS DayNameOfWeek,
		DATEPART(DD, @CurrentDate) AS DayOfMonth,
		DATEPART(DY, @CurrentDate) AS DayOfYear,

		CASE DATEPART(DW, @CurrentDate)
			WHEN 1 THEN 'Weekend'
			WHEN 2 THEN 'Weekday'
			WHEN 3 THEN 'Weekday'
			WHEN 4 THEN 'Weekday'
			WHEN 5 THEN 'Weekday'
			WHEN 6 THEN 'Weekday'
			WHEN 7 THEN 'Weekend'
			END AS WeekdayWeekend,

		DATEPART(ISO_WEEK, @CurrentDate) AS WeekOfYear,
		DATENAME(MM, @CurrentDate) AS MonthName,
		Convert(VARCHAR(3), DATENAME(Month, @CurrentDate)) AS MonthNameShort,
		DATEPART(MM, @CurrentDate) AS MonthOfYear,
		
		CASE DATEPART(DD, @CurrentDate)
			WHEN 1 THEN 'Y'
            ELSE 'N'
			END AS IsFirstDayOfMonth,

		CASE
			WHEN DateAdd(day, -1, DateAdd(month, DateDiff(month, 0, @currentDate) + 1, 0)) = @currentDate THEN 'Y' 
			ELSE 'N'
			END AS IsLastDayOfMonth,

		DATEPART(QQ, @CurrentDate) AS Quarter,
		DATEPART(YEAR, @CurrentDate) AS Year,
		LEFT(CONVERT(VARCHAR, DATEPART(Year, @CurrentDate)),4) + 
		right('0' + convert(varchar, datepart(WW, dateadd(day, -7 , @CurrentDate))), 2) AS YearWeek,
		CONVERT(VARCHAR(7), @CurrentDate, 126) AS 'Year-Month',
		CONVERT(VARCHAR(6), @CurrentDate, 112) AS YearMonth,
		LEFT(DATENAME(YY, @CurrentDate), 4) + 'Q' + CONVERT(VARCHAR,
		DATEPART(QQ, @CurrentDate)) AS YearQuarter

	SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END

/*****************************************************************************************/

SELECT * FROM [dbo].[DimDate]