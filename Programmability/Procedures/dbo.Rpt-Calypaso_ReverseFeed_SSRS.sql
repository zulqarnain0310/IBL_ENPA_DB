SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[Rpt-Calypaso_ReverseFeed_SSRS]
@DtEnter		VARCHAR(10)
AS


--DECLARE
--@DtEnter		VARCHAR(10)='31-03-2018'
 
DECLARE @TimeKey   INT

SELECT @TimeKey=TimeKey FROM SysDataMatrix WHERE MonthLastDate=CONVERT(DATE,@DtEnter,105)

IF OBJECT_ID ('TEMPDB..#Temp')IS NOT NULL
DROP TABLE 	#Temp

IF OBJECT_ID ('TEMPDB..#Temp1')IS NOT NULL
DROP TABLE 	#Temp1


select NCIF_Id,SrcSysAlt_Key,CustomerId,CustomerName,NCIF_AssetClassAlt_Key,NCIF_NPA_Date,CustomerACID,AC_AssetClassAlt_Key,
AC_NPA_Date into #Temp from NPA_IntegrationDetails A
       where  A.EffectiveFromTimeKey<=@TimeKey and A.EffectiveToTimeKey>=@TimeKey   and SrcSysAlt_Key=40 

select NCIF_Id,SrcSysAlt_Key,CustomerId,NCIF_AssetClassAlt_Key,NCIF_NPA_Date,CustomerACID,AC_AssetClassAlt_Key,
AC_NPA_Date into #Temp1 from NPA_IntegrationDetails A
       where  A.EffectiveFromTimeKey <=@TimeKey and A.EffectiveToTimeKey >=@TimeKey and SrcSysAlt_Key<>40 

------insert into Calypao_ReverseFeed (
------ SrNo
------,[CounterParty.ID]
------,[CounterParty.Short Name]
------,[CounterParty.Attribute.UCIC]
------,[CounterParty.Attribute.Asset_Class_Description]
------,[CounterParty.Attribute.Asset_Classification_Code]
------,[CounterParty.Attribute.NPA Date]
------,[CounterParty.Attribute.UCIC_pcrd])
select 
ROW_NUMBER()OVER (ORDER BY a.NCIF_Id,a.CustomerID)SrNo,
a.CustomerId,a.CustomerName,a.NCIF_Id,D.AssetClassShortName,B.AC_AssetClassAlt_Key, B.AC_NPA_Date,b.NCIF_Id as UCIC_pcrd from #Temp a
INNER JOIN #Temp1 b on a.NCIF_Id=b.NCIF_Id 
INNER JOIN DimAssetClass D on D.AssetClassAlt_Key=a.NCIF_AssetClassAlt_Key
AND D.EffectiveFromTimeKey <=@TimeKey and D.EffectiveToTimeKey >=@TimeKey
where a.NCIF_AssetClassAlt_Key<>1
--and a.CustomerId<>a.NCIF_Id





GO