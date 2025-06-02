SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[Rpt-ReportVersion]      
(
 @ReportName AS VARCHAR(MAX)
 ,@DtEnter AS VARCHAR(10)
)
  AS

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))


DECLARE @TimeKey as Varchar(20)=(select TimeKey from SysDayMatrix where SysDayMatrix.Date=@DtEnter1)

declare @reptitle AS VARCHAR(MAX)      
declare @value AS INT      
SET @reptitle =RIGHT(@reportname,charindex('-',reverse(@reportname))-1)       
SET @value=(SELECT CASE WHEN (SELECT ReportRdlName FROM SysReportDirectory WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey  and  ReportRdlName=@reptitle)=@reptitle      
THEN 1 ELSE 2 END)      
IF @value =1      
 BEGIN      
  SELECT ('Version No. : '+VersionNo)  AS versionno,('Report ID : '+ReportID) as reportid        
  , Frequency_Period        
        
  ,CASE WHEN ReportType IN (3,4) THEN 'Summary'   
        WHEN  ReportType IN (1,2) THEN 'List'   
        WHEN  ReportType = 5 THEN 'SummaryList'  
		END AS ReportTypeLabel    
      
      
  , ReportType       AS ReportTypeValue     
        
  FROM SysReportDirectory WHERE ReportRdlName=@reptitle AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey     
 END      
IF @value =2      
 BEGIN      
  SELECT ('Version No. : '+VersionNo)  AS versionno,('Report ID : '+ReportID) as reportid       
        
  ,CASE WHEN ReportType = 1    
        THEN 'Summary' ELSE 'Details' END AS ReportTypeLabel    
      
      
  ,CASE WHEN ReportType = 1    
        THEN '1' ELSE '2' END AS ReportTypeValue      
        
   FROM ValidationReport  WHERE recordstatus='C' and ReportRdlName=@reptitle      
 END      
ELSE      
 BEGIN      
  SELECT '' AS versionno      
 END 
 




GO