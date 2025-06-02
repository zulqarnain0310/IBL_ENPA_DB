SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
Created By :- Vedika
Created Date:-26/10/2017
Report Name :- Upgradation of Accounts
*/

CREATE PROC [dbo].[Rpt-Upgradation_Accounts]
@DtEnter as varchar(20)
,@Cost as Float
,@DimsourceSystem as int
AS

--DECLARE	
--@DtEnter as varchar(20)='31/03/2018'
--,@Cost AS FLOAT=1000
--,@DimsourceSystem as int=0


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 



SELECT 


DSS.SourceName										            AS 'SourceSystem'


,NPAID.NCIF_Id									                AS 'NCIF'


,NPAID.CustomerID								                AS 'CustomerID'


,NPAID.CustomerName							                    AS 'CustomerName'


,NPAID.PAN										                AS 'PAN'
												                
,NPAID.ProductType								                AS 'Facility'

,case when len(NPAID.CustomerACID)=16
				then '''' + NPAID.CustomerACID + '''' 
				else NPAID.CustomerACID
				end												AS 'Account No.'

,ISNULL(NPAID.SanctionedLimit,0)/@Cost			                AS 'Limit'

,ISNULL(NPAID.Balance,0)/@Cost					                AS 'Outstanding'

,ISNULL(NPAID.DrawingPower,0)/@Cost			                    AS 'DP'

,ISNULL(NPAID.PrincipleOutstanding,0)/@Cost                     AS 'POS'

,NPAID.SubSegment								                AS 'SubSegment'
												                
,NPAID.ProductDesc								                AS 'ProductDesc'

,NPAID.ProductCode											    AS 'ProductCode'

,NPAID.ProductDesc										        AS 'ProudctDescription'

,DimAssetClass.AssetClassName	                                AS 'ACASSET'

,convert(varchar(20),NPAID.AC_NPA_Date,103)	                    AS 'AC_NPADate'

,NCIFASSET.AssetClassName 	                                    AS 'NCIFASSET'

,convert(varchar(20),NCIF_NPA_Date,103)	                        AS 'NCIF_NPADate'

,NPAID.SrcSysAlt_Key
,ActualOutStanding
,PrincipleOutstanding
,ActualPrincipleOutstanding
,NPAID.CUSTOMER_IDENTIFIER



FROM NPA_IntegrationDetails	NPAID	        

INNER JOIN DimAssetClass				    ON DimAssetClass.AssetClassAlt_Key=NPAID.AC_AssetClassAlt_Key
										       AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
                                               AND NPAID.EffectiveFromTimeKey<=@TimeKey AND NPAID.EffectiveToTimeKey>=@TimeKey

INNER JOIN DimAssetClass NCIFASSET		    ON NCIFASSET.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key
										       AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
										
INNER JOIN DimSourceSystem	DSS			    ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
										        AND DSS.EffectiveFromTimeKey<=@TimeKey AND DSS.EffectiveToTimeKey>=@TimeKey
										



WHERE FlgUpg='Y' AND  ( DSS.SourceAlt_Key=@DimsourceSystem OR @DimsourceSystem=0)

OPTION(RECOMPILE)





GO