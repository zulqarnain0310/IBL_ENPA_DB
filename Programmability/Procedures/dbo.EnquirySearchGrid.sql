SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[EnquirySearchGrid]
 @DateOfData	VARCHAR(10)
,@SelectLevel	VARCHAR(10)
,@EnterId		VARCHAR(20)
,@Result		INT =0 
,@ApproRejctFlag CHAR(1)
,@UserID varchar(20)
,@SearchLevel  VARCHAR(10) 
--DECLARE
-- @DateOfData	VARCHAR(10)
--,@SelectLevel	VARCHAR(10)
--,@EnterId		VARCHAR(20)
--,@Result		INT =0 
--,@ApproRejctFlag CHAR(1)

AS 


DECLARE
@TimeKey INT =(SELECT TimeKey  FROM SysDaymatrix  WHERE CAST([DATE] AS DATE)=CAST(@DateOfData AS DATE))

IF @ApproRejctFlag='A'
	BEGIN              
	                --DECLARE  @codeName varchar(20)
                 --   SET @codeName = 'ACR,C'

                    IF OBJECT_ID('Tempdb..#temp') IS NOT NULL
				       DROP TABLE   #temp

		             SELECT 
		             		Split.a.value('.', 'VARCHAR(100)') AS String  ,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS SNO 
		             		INTO #temp
		             FROM  
		             (
		                 SELECT 
		                     CAST ('<M>' + REPLACE(@SelectLevel, ',', '</M><M>') + '</M>' AS XML) AS Data  
		                
		             ) AS A CROSS APPLY Data.nodes ('/M') AS Split(a); 

		          SET @SearchLevel=(SELECT String from #temp WHERE SNO=2)
				  SET @SelectLevel=(SELECT String from #temp WHERE SNO=1)

				  PRINT @SearchLevel
				  PRINT @SelectLevel
			
	

						SELECT
						 A.CustomerId AS ClientID
						,A.AccountEntityID
					    ,A.CustomerACID
						,'TblSearchGrid' AS TableName 
								
						 FROM NPA_IntegrationDetails A
						 INNER JOIN NPA_IntegrationDetails_MOD  B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
																		AND A.AccountEntityID=B.AccountEntityID
																		AND B.AuthorisationStatus='A'
																		AND B.ApprovedBy IS NOT NULL
																		AND B.DateApproved IS NOT NULL
					
						 WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
								--AND (CASE WHEN @SelectLevel='C' THEN A.CustomerId = @EnterId ELSE A.PAN=@EnterId END)
								AND (CASE WHEN @SearchLevel = 'C' AND A.CustomerId = @EnterId THEN 1 
                                        WHEN @SearchLevel = 'P' AND A.PAN=@EnterId THEN 1 END )= 1
								AND A.AuthorisationStatus='A' 
								AND A.ApprovedBy IS NOT NULL
								AND A.DateApproved IS NOT NULL
						
	END

ELSE
		BEGIN
				
						SELECT 
						 CustomerId AS ClientID
						,AccountEntityID
					    ,CustomerACID
						,'TblSearchGrid' AS TableName 		
						
						 FROM NPA_IntegrationDetails_MOD
						 WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND CustomerId=@EnterId
								AND AuthorisationStatus='R'
				


		END


GO