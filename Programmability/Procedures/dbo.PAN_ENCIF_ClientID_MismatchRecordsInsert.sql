SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[PAN_ENCIF_ClientID_MismatchRecordsInsert]

@TimeKey  INT

AS


--DECLARE
--@TimeKey  INT=24745

/*CUSTOMER ID WISE NCIF MISMATCH */

IF OBJECT_ID ('TEMPDB..#ClientIdNCIF_Mismatch')IS NOT NULL
DROP TABLE #ClientIdNCIF_Mismatch

SELECT A.SrcAppCustomerID CustomerID,A.NCIF NCIF_Id,A.SrcAppAlt_Key SrcSysAlt_Key, C.CustomerName,A.PAN INTO #ClientIdNCIF_Mismatch FROM DedupSysData A
INNER JOIN 
(
	SELECT COUNT(DISTINCT NCIF)CNT,SrcAppCustomerID FROM DedupSysData 
	WHERE EffectiveFromTimeKey=@TimeKey 
	--AND ISNULL(NCIF,'')<>'' 
	AND ISNULL(SrcAppCustomerID,'')<>''
	GROUP BY SrcAppCustomerID
	HAVING COUNT(DISTINCT NCIF)>1
)B  ON A.SrcAppCustomerID=B.SrcAppCustomerID

LEFT JOIN NPA_IntegrationDetails   C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
										  AND A.SrcAppCustomerID=C.CustomerId
										  AND A.NCIF=C.NCIF_Id

WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
GROUP BY A.SrcAppCustomerID,A.NCIF,A.SrcAppAlt_Key,C.CustomerName,A.PAN
ORDER BY A.SrcAppCustomerID

IF EXISTS(SELECT 1 FROM #ClientIdNCIF_Mismatch WHERE 1=1)
	BEGIN
				DELETE A FROM ClientID_NCIF_MismatchDetails A

				INNER JOIN #ClientIdNCIF_Mismatch      B  ON     A.TimeKey=@TimeKey AND 
																(A.CustomerID=B.CustomerID) AND
																(A.NCIF=B.NCIF_Id)

				INNER JOIN NPA_IntegrationDetails			  C        ON   (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey) 
																AND (A.CustomerID=C.CustomerID)  
																AND (A.NCIF=C.NCIF_Id)


				INSERT INTO     ClientID_NCIF_MismatchDetails
				(
					 SrcSysAlt_Key
					,CustomerId
					,NCIF
					,CustomerName
					,PAN
					,TimeKey
				)
				
				SELECT 
				DISTINCT
				 A.SrcSysAlt_Key
				,A.CustomerId
				,A.NCIF_Id
				,A.CustomerName
				,A.PAN
				,@TimeKey
				 
				FROM #ClientIdNCIF_Mismatch	A
																
	END

/*CUSTOMER ID WISE NCIF MISMATCH */



/*PAN WISE NCIF MISMATCH*/ -- Truncate table NCIF_MismatchDetails

IF OBJECT_ID('TEMPDB..#PAN_NCIF_Mismatch')IS NOT NULL
DROP TABLE #PAN_NCIF_Mismatch 


SELECT A.PAN,A.NCIF_Id,A.SrcSysAlt_Key, A.CustomerId,A.CustomerName INTO #PAN_NCIF_Mismatch FROM NPA_IntegrationDetails A
INNER JOIN 
(

SELECT COUNT(DISTINCT NCIF_Id)CNT,PAN FROM NPA_IntegrationDetails 
WHERE EffectiveFromTimeKey=@TimeKey 
AND  ISNULL(PAN,'')<>''    ---SHISHIR SIR	
													AND  LEN(PAN)=10 
													AND  PAN LIKE'%[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]%' ---- AS discussed with Shishi sir
--AND ISNULL(NCIF,'')<>''
GROUP BY PAN
HAVING COUNT(DISTINCT NCIF_Id)>1
)B  ON A.PAN=B.PAN
--LEFT JOIN NPA_IntegrationDetails   C   ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
--											AND C.NCIF_Id=A.NCIF
--											AND C.CustomerId=A.CustomerId

WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
GROUP BY A.PAN,A.NCIF_Id,A.SrcSysAlt_Key,A.CustomerId,A.CustomerName
ORDER BY A.PAN

IF EXISTS(SELECT 1 FROM #PAN_NCIF_Mismatch WHERE 1=1)
	BEGIN
						
			DELETE A FROM NCIF_MismatchDetails A
				INNER JOIN #PAN_NCIF_Mismatch            B  ON      (A.PAN=B.PAN)
																AND A.NCIF=B.NCIF_Id

				INNER JOIN NPA_IntegrationDetails			  C        ON   (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND (A.PAN=C.PAN)  
															   AND (A.NCIF=C.NCIF_Id)
														
			WHERE A.TimeKey=@TimeKey													


				INSERT INTO NCIF_MismatchDetails
				(
					 NCIF
					,PAN
					,CustomerID
					,SrcSysAlt_Key
					,CustomerName
					,TimeKey

				)

				SELECT 
				DISTINCT
				 NCIF_Id
				,PAN
				,CustomerId
				,SrcSysAlt_Key
				,CustomerName
				,@TimeKey
				
				 FROM #PAN_NCIF_Mismatch

	 END				



/*PAN WISE NCIF MISMATCH*/ ----Truncate table PAN_MismatchDetails


/*PAN MISMATCH*/

IF OBJECT_ID('TEMPDB..#PanMismatch')IS NOT NULL
DROP TABLE #PanMismatch

SELECT A.NCIF_Id,A.PAN ,A.SrcSysAlt_Key,A.CustomerId,A.CustomerName INTO #PanMismatch FROM NPA_IntegrationDetails A
INNER JOIN 
(
	SELECT COUNT(DISTINCT PAN)CNT,NCIF_Id FROM NPA_IntegrationDetails 
	WHERE EffectiveFromTimeKey=@TimeKey 
	AND  ISNULL(PAN,'')<>''    ---SHISHIR SIR	
													AND  LEN(PAN)=10 
													AND  PAN LIKE'%[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]%' ---- AS discussed with Shishi sir
	AND ISNULL(NCIF_Id,'')<>''
	GROUP BY NCIF_Id
	HAVING COUNT(DISTINCT PAN)>1
)B  ON A.NCIF_Id=B.NCIF_Id
--LEFT JOIN NPA_IntegrationDetails C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
--										 AND C.NCIF_Id=A.NCIF
--										 AND C.CustomerId=A.CustomerId

WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
GROUP BY A.NCIF_Id,A.PAN,A.SrcSysAlt_Key,A.CustomerId,A.CustomerName
ORDER BY A.NCIF_Id


IF EXISTS(SELECT 1 FROM #PanMismatch WHERE 1=1)
	BEGIN

				DELETE A FROM PAN_MismatchDetails A
				INNER JOIN #PanMismatch            B        ON   (A.NCIF=B.NCIF_Id)
																  AND A.PAN=B.PAN 

				INNER JOIN NPA_IntegrationDetails			  C         ON  (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey) 
																AND (A.NCIF=C.NCIF_Id)
													            AND(A.PAN=C.PAN)
				WHERE A.TimeKey=@TimeKey													


				INSERT INTO PAN_MismatchDetails
				(
					 NCIF
					,PAN
					,CustomerID
					,SrcSysAlt_Key
					,CustomerName
					,TimeKey
				)

				SELECT
				DISTINCT 
				 NCIF_Id
				,PAN
				,CustomerId
				,SrcSysAlt_Key
				,CustomerName
				,@TimeKey
				FROM #PanMismatch


	  END				

/*PAN MISMATCH*/
GO