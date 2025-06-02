SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--USE [IndusInd]
--GO
--/****** Object:  StoredProcedure [dbo].[Rpt-MissingPAN]    Script Date: 10/4/2017 6:11:07 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--/*
--ALTERd By :- Vedika
--ALTERd Date:-26/09/2017
--Report Name :-Missing PAN 

--*/

CREATE  proc [dbo].[Rpt-MissingPAN]
@DtEnter as varchar(20)
,@Cost AS FLOAT
AS

--DECLARE	

--@DtEnter as varchar(20)='30/09/2017'
--,@Cost AS FLOAT=1000

DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1


DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)
----Print @TimeKey 


select * into #temp
From
(
SELECT COUNT(DISTINCT CustomerId)CustomerId
 ,NCIF_Id 
 FROM NPA_IntegrationDetails
 where NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
 GROUP BY NCIF_Id
 HAVING COUNT(DISTINCT CustomerId)>1
 )temp

  
  
SELECT 

DimSourceSystem.SourceName		 AS 'SourceSystem',

A. NCIF_Id						 AS 'NCIF'

,A.CustomerId					 AS 'CustomerID'

,A.CustomerName					 AS 'CustomerName'
	  
,A.PAN						    AS 'PAN'
	
,A.ProductType					AS 'Facility'	
	
,A.CustomerACID				    AS 'Account No.'	
	  
,A.Balance						AS 'Outstanding'        
	  
,A.SanctionedLimit			 	AS 'Limit'	
	  
FROM NPA_IntegrationDetails A

INNER JOIN  ( SELECT NCIF_Id, ([1]+ isnull(' , ' +[2],'')   +	 isnull(' , ' +[3],'') +	isnull(' , ' +[4],'') +	isnull(' , ' +[5],'') +	isnull( ' , ' +[6],'') +	isnull(' , ' +[7],'') +
				   isnull(' , ' +[8],'') +	isnull(' , ' +[9],'') +	isnull(' , ' +[10],'') +	isnull(' , ' +[11],'') +	isnull(' , ' +[12],'') +	isnull(' , ' +[13],'') +
				   isnull(' , ' +[14],'') + 	isnull(' , ' +[15],''))   AS PAN   
								FROM (SELECT    NPA_IntegrationDetails.NCIF_Id,PAN , ROW_NUMBER() OVER(PARTITION BY  NPA_IntegrationDetails.NCIF_Id
								Order By  PAN) A FROM  NPA_IntegrationDetails 
													
												INNER JOIN #temp on  #temp.ncif_ID=NPA_IntegrationDetails.ncif_ID
																	and NPA_IntegrationDetails.EffectiveFromTimeKey<=@TimeKey and NPA_IntegrationDetails.EffectiveToTimeKey>=@TimeKey
										


								
								 ) PVT
								PIVOT  ( MIN (PVT.PAN) FOR A IN ( [1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15] )) AS tuff

								) B  ON A.NCIF_Id=B.NCIF_Id
								     AND B.PAN  IS NULL
								


INNER JOIN DimSourceSystem				ON  DimSourceSystem.SourceAlt_Key=A.SrcSysAlt_Key
										AND DimSourceSystem.EffectiveFromTimeKey<=@TimeKey AND DimSourceSystem.EffectiveToTimeKey>=@TimeKey


order by A.NCIF_Id


option(recompile)



GO