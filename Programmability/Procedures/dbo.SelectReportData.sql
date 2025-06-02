SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

---SelectReportParams 92405,3652
CREATE PROCEDURE [dbo].[SelectReportData] 
    @ReportID int = 1040
   
AS

begin 

Select   DimReportFrequency.ReportFrequencyName as Frequency,TblReportDirectory.* from SysReportDirectory TblReportDirectory
left JOIN DimReportFrequency on DimReportFrequency.ReportFrequencyAlt_Key=TblReportDirectory.ReportFrequency_Key
where ReportMenuId=@ReportID
order by Reportid


End

GO