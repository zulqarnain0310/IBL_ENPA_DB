SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--exec UserParameterParameterisedMasterData 'Y','Y',2922
CREATE PROCEDURE [dbo].[UserParameterParameterisedMasterData_12082021]
(
	@blnFetchMetaData as CHAR(1),
	@blnFetchMasterData as CHAR(1),
	@TimeKey SMALLINT	-- NITIN : 21 DEC 2010
)
AS
BEGIN
--DECLARE @TimeKey AS SMALLINT -- NITIN : 21 DEC 2010
--SET @TimeKey =(SELECT MonthKey  FROM DimMonthMatrix WHERE CurrentStatus='C' ) -- NITIN : 21 DEC 2010
SELECT CtrlName
					,FldName
					,FldCaption
					,FldDataType
					,FldLength
					,ErrorCheck
					,DataSeq
					,CriticalErrorType
					,MsgFlag
					,MsgDescription
					,ReportFieldNo
					,ScreenFieldNo
					,ViableForSCD2

					  from metaUserFieldDetail WHERE FrmName ='frmUserPolicy' 

--SELECT 
--SeqNo,
--ParameterType,
--ParameterValue,
--ShortNameEnum,
--MinValue,
--MaxValue,
--EffectiveFromTimeKey,
--EffectiveToTimeKey,
--AuthorisationStatus ,
--'N' AS IsMainTable
--from DimUserParameters 
-- WHERE (DimUserParameters.EffectiveFromTimeKey <=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
 
-- ORDER BY SeqNo


 --------------------------
 IF OBJECT_ID('Tempdb..#temp') IS NOT NULL
						DROP TABLE #temp
			
SELECT 
--SeqNo,
--ParameterType,
--ParameterValue,
--ShortNameEnum,
--MinValue,
--MaxValue,
--EffectiveFromTimeKey,
--EffectiveToTimeKey,
--AuthorisationStatus ,
--IsMainTable,
--CreatedModifiedBy
						*	INTO #temp

  FROM (
SELECT	
 SeqNo,
ParameterType,
ParameterValue,
ShortNameEnum,
MinValue,
MaxValue,
EffectiveFromTimeKey,
EffectiveToTimeKey,
SR.AuthorisationStatus ,	
				'N' AS IsMainTable
				,  CASE WHEN ISNULL(SR.ModifyBy,'')='' THEN SR.CreatedBy ELSE SR.ModifyBy END  AS CreatedModifiedBy
		FROM [dbo].[DimUserParameters_mod] SR
		INNER JOIN (	SELECT AuthorisationStatus FROM [dbo].[DimUserParameters_mod] SER
											INNER JOIN (SELECT MAX(EntityKey) EntityKey FROM [dbo].[DimUserParameters_mod] SR 
															WHERE AuthorisationStatus IN('NP','MP','DP','RM') 
															AND (SR.EffectiveFromTimeKey <=@TimeKey AND SR.EffectiveToTimeKey >=@TimeKey )
															--AND SR.AssetBlockAlt_key=@AssetBlockAlt_key 
															GROUP BY EntityKey
														) A ON (SER.EffectiveFromTimeKey <=@TimeKey AND SER.EffectiveToTimeKey >=@TimeKey )	
											AND A.EntityKey =SER.EntityKey
											--AND SER.AssetBlockAlt_key=@AssetBlockAlt_key 
											GROUP BY AuthorisationStatus		
				) S
				ON (SR.EffectiveFromTimeKey <=@TimeKey AND SR.EffectiveToTimeKey >=@TimeKey )	
				AND SR.AuthorisationStatus=S.AuthorisationStatus
				--WHERE AssetBlockAlt_key = @AssetBlockAlt_key 
				--AND (SR.EffectiveFromTimeKey <=@TimeKey AND SR.EffectiveToTimeKey >=@TimeKey )
		UNION
		SELECT	SeqNo,
				ParameterType,
				ParameterValue,
				ShortNameEnum,
				MinValue,
				MaxValue,
				EffectiveFromTimeKey,
				EffectiveToTimeKey,
				AuthorisationStatus ,

				'Y' AS IsMainTable
				, CASE WHEN ISNULL(SR.ModifyBy,'')='' THEN SR.CreatedBy ELSE SR.ModifyBy END  AS CreatedModifiedBy
		FROM [dbo].[DimUserParameters] SR
		WHERE  ISNULL(AuthorisationStatus,'A') ='A'
		AND (SR.EffectiveFromTimeKey <=@TimeKey AND SR.EffectiveToTimeKey >=@TimeKey )
		)Temp
	


	Select * from #temp
 ------------------------------




--SELECT MsgDescription  
--		,ParameterType
--		,ParameterValue
--		,MinValue
--		,MaxValue
--		,'N' AS IsMainTable
--		FROM metaUserFieldDetail  meta
--		INNER JOIN DimUserParameters dimUser
--		ON meta.FldCaption = dimUser.ShortNameEnum
		
--		WHERE FrmName ='frmUserPolicy' 
--		AND (dimUser.EffectiveFromTimeKey <=@TimeKey AND dimUser.EffectiveToTimekey>=@TimeKey) 
--		ORDER BY SeqNo



SELECT MsgDescription  
		,ParameterType
		,ParameterValue
		,MinValue
		,MaxValue
		,IsMainTable
		,CreatedModifiedBy
		,D.UserLocation
		FROM metaUserFieldDetail  meta
		INNER JOIN #temp dimUser
		ON meta.FldCaption = dimUser.ShortNameEnum
		left join DimUserInfo D
		ON D.UserLoginID=dimuser.CreatedModifiedBy
		WHERE FrmName ='frmUserPolicy' 
		AND (dimUser.EffectiveFromTimeKey <=@TimeKey AND dimUser.EffectiveToTimekey>=@TimeKey) 
		ORDER BY SeqNo



END





GO