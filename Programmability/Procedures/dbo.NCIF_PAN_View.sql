SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROC [dbo].[NCIF_PAN_View]
	 @TimeKey INT=49999
	,@SearchBy CHAR(1)='P'  ---> E-ENCIF, P-Pan
	,@SearchID VARCHAR(MAX)='10504757'
AS
BEGIN

			SET @TimeKey=(SELECT TimeKey FROM SysDataMatrix_API WHERE CurrentStatus='C') 

			DROP TABLE IF EXISTS #UCIF
			CREATE TABLE #UCIF (Items VARCHAR(max))

			INSERT INTO #UCIF 
			SELECT * FROM split(@SearchID,',')

			DROP TABLE IF EXISTS #CTE 
			CREATE TABLE #CTE (NCIF_Id VARCHAR(30),CustomerID VARCHAR(30))

			IF @SearchBy='E'
			BEGIN
					INSERT INTO #CTE
					SELECT  A.NCIF_Id,A.CustomerID  
					FROM NPA_IntegrationDetails_API A 
					WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
					AND @SearchBy='E' 
					AND ISNULL(A.NCIF_Id,'')<>''
					AND EXISTS (SELECT Items FROM #UCIF B WHERE B.Items=A.NCIF_Id)
			END	 
			
			IF @SearchBy='P'
			BEGIN
					INSERT INTO #CTE
					SELECT  A.NCIF_Id,A.CustomerID 
					FROM NPA_IntegrationDetails_API A   
					WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
					AND @SearchBy='P'
					AND ISNULL(A.PAN,'')<>'' 
					AND EXISTS (SELECT Items FROM #UCIF B WHERE B.Items=A.PAN)
			END						


				DROP TABLE IF EXISTS #NCIF_DATA
				CREATE TABLE #NCIF_DATA
				(
					NCIF_Id VARCHAR(30),
					CustomerID VARCHAR(30)
				)

				INSERT INTO #NCIF_DATA(NCIF_Id,CustomerID)
				SELECT  NCIF_Id,CustomerID  
				FROM #CTE 
				GROUP BY NCIF_Id,CustomerID  
			 
			
				DROP TABLE IF EXISTS #Aadhardata
			
				SELECT DISTINCT UCIC,AADHAR_NO,KYCID,A.CustomerID 
				INTO #Aadhardata 
				FROM D2K_AADHAR_VOTER_ALL(NOLOCK) a 
				INNER JOIN #NCIF_DATA b ON a.UCIC=b.NCIF_Id 
										AND a.CustomerID=b.CustomerID 

		     	SELECT
                  	   ROW_NUMBER() OVER(ORDER BY (SELECT 1))	AS [Sr No]
                  	  ,A.NCIF_Id								AS [NCIF ID]
                  	  ,D.SourceName								AS [SourceName]
                  	  ,A.CustomerId								AS [Customer Id]
                  	  ,A.CustomerName							AS [Customer Name]

                  	  ,A.CustomerACID							AS [Account ID]
                  	  ,A.Segment								AS [Segment Code]
                  	  ,A.ProductCode							AS [Product Code]
					  ,A.ProductDesc							AS [Product Description]	 
                  	  ,A.FacilityType							AS [Facility Type]
					  ,A.IsFunded								AS [Is Funded]

                  	  ,ISNULL(A.PrincipleOutstanding,0.00)		AS [Principle Outstanding]
                  	  ,ISNULL(A.Balance,0.00)					AS Balance

                  	  ,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)	AS [Ac NPA Dt]
                  	  ,A.NCIF_AssetClassAlt_Key					AS [NCIF Asset Class]
                  	  ,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103) AS [NCIF NPA Dt]
                  	  ,A.MaxDPD									AS [MaxDPD]			
                  	  ,(CASE WHEN A.NCIF_AssetClassAlt_Key=1 
							THEN 'STD' ELSE 'NPA' END)			AS [Status]
					  ,A.[SecuredFlag]							AS [Secured Flag]
					  ,A.[FlgErosion]							AS [Erosion Flag]

					  ,A.[DCCO_Date]							AS [DCCO Dt]
					  ,A.[StkStmtDate]							AS [Stock Stmt Dt]

					  ,A.PAN									AS [PAN]
					  ,F.[AADHAR_NO]							AS [AADHAR No]
					  ,F.[KYCID]								AS [Voter ID]

                  	  ,A.IsARC_Sale								AS [ARCFLAG]					
                  	  ,CONVERT(VARCHAR(10),A.ARC_SaleDate,103)  AS [ARC Sale Dt]
                  	  ,A.IsRestructured							AS [IsRestructured]
                  	  ,CONVERT(VARCHAR(10),C.RestructureDt,103) AS [Restructure Dt]
                  	  ,A.IsOTS									AS [OTS]
                  	  ,A.IsFraud								AS [Fraud]
                  	  ,A.IsTWO									AS [WriteOffFlag]
                  	  ,CONVERT(VARCHAR(10),A.WriteOffDate,103)	AS [Writeoffdate]
					  ,A.IsSuitFiled							AS [Is Suite Filed] 

                FROM NPA_IntegrationDetails_API A						 
   			    INNER JOIN #NCIF_DATA E			ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
			    								AND A.NCIF_Id=E.NCIF_ID  AND A.CustomerID=E.CustomerID
                LEFT JOIN CURDAT.AdvAcRestructureDetail_API C	ON A.AccountEntityId=C.AccountEntityId
                												AND (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
			    LEFT JOIN DimSourceSystem D		ON A.SrcSysAlt_Key=D.SourceAlt_Key        
                								AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey) 
			    LEFT JOIN #Aadhardata F			ON A.NCIF_Id = F.[UCIC] 
			    								AND A.CustomerID=F.CustomerID
			    ORDER BY A.[SrcSysAlt_Key] , A.NCIF_Id , A.CustomerId , A.CustomerACID
			 
			DROP TABLE IF EXISTS #CTE
			DROP TABLE IF EXISTS #UCIF
			DROP TABLE IF EXISTS #NCIF_DATA
			DROP TABLE IF EXISTS #Aadhardata

	END			


GO