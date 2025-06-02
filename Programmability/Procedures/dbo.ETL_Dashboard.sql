SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Satwaji
Created Date	:- 17/09/2021
Screen Name		:- ETL Dashboard 
*/

CREATE  proc [dbo].[ETL_Dashboard]
		@DisplayDate VARCHAR(10)
AS
BEGIN
--DECLARE	
--@DisplayDate AS INT=26084,

--SET @DisplayDate = CONVERT(DATE,@DisplayDate,103)
--PRINT @DisplayDate

Select Process , [Execution Start Time], [Execution End Time], [Duration in Minuets]
From
(
	SELECT 
		DimETLDash.ETL_DashboardEntityName as 'Process' , 
		FORMAT (Pack_AUDIT.ExecutionStartTime, 'dd/MM/yyyy, hh:mm:ss tt') as 'Execution Start Time', 
		FORMAT (Pack_AUDIT.ExecutionEndTime, 'dd/MM/yyyy, hh:mm:ss tt') as 'Execution End Time', 
		Pack_AUDIT.TimeDuration_Min as 'Duration in Minuets' , DimETLDash.ETL_DashboardEntityAlt_Key AS ETL_DashboardEntityAlt_Key
	From 
		[IBL_ENPA_STGDB].[dbo].[Package_AUDIT] Pack_AUDIT
	Inner Join -- Change done to take additional information from Master
		DimETL_DashboardEntity  DimETLDash
		On Pack_AUDIT.SourceName=DimETLDash.SrcSysETL_DashboardEntityName
	Where 
		Pack_AUDIT.Execution_date=CONVERT(DATE,@DisplayDate,103) and DimETLDash.ETL_DashboardEntityValidCode = 'Y'
	Union All
		
	
    SELECT 
		DimETLDash.ETL_DashboardEntityName as 'Process' , 
		FORMAT (Proc_AUDIT.Start_Date_Time, 'dd/MM/yyyy, hh:mm:ss tt') as 'Execution Start Time', 
		FORMAT (Proc_AUDIT.End_Date_Time, 'dd/MM/yyyy, hh:mm:ss tt') as 'Execution End Time', 
		Proc_AUDIT.TimeDuration_Min  as 'Duration in Minuets' , DimETLDash.ETL_DashboardEntityAlt_Key AS ETL_DashboardEntityAlt_Key
	From 
		[IBL_ENPA_STGDB].[dbo].[Procedure_Audit] Proc_AUDIT
	Inner Join -- Change done to take additional information from Master
		DimETL_DashboardEntity DimETLDash
		On Proc_AUDIT.SP_Name=DimETLDash.SrcSysETL_DashboardEntityName
	Where 
		Proc_AUDIT.EXT_DATE=CONVERT(DATE,@DisplayDate,103) and DimETLDash.ETL_DashboardEntityValidCode = 'Y'
) ETL_Dashboard
Order By
		ETL_DashboardEntityAlt_Key , [Execution Start Time]

OPTION(RECOMPILE)
--GO

END
GO