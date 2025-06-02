SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[EnquiryScreenDownloadData_16112021]
		 @UniqueUploadID INT				= 0
		,@UploadedBy VARCHAR(50)			= ''
		,@DateOfUpload VARCHAR(10)			= ''
		,@AuthorisationLevel	VARCHAR(50)	= ''
		,@AuthorisedBy VARCHAR(50)			= ''
		,@AuthorisedDate VARCHAR(10)		= ''
		--,@Timekey INT				
		--,@UserLoginId VARCHAR(100)			= ''
AS

--DECLARE
--	 @DateOfData VARCHAR(10)	= '23/06/2021'
--	,@UploadType VARCHAR(50)	= 'Customer MOC Upload'
--	,@UploadStatus VARCHAR(20)	= 'Pending'

BEGIN
		SET NOCOUNT ON;

		DECLARE @Timekey INT

		DECLARE @UploadType VARCHAR(50)

		SET @UploadType=(SELECT 
								CASE WHEN UploadType='Buyout Upload' THEN 'Securitization Upload' ELSE UploadType END AS UploadType 
						 FROM ExcelUploadHistory WHERE UniqueUploadId=@UniqueUploadID)
						 --AND (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey))

		--SET @Timekey=(SELECT CAST(timekey as int) from SysDaymatrix WHERE CONVERT(Date,DATE,103)=CONVERT(DATE,@DateOfUpload,103))
		IF (@UploadType='Account MOC Upload' OR @UploadType='Customer MOC Upload')
			Set @Timekey=(select CAST(B.timekey as int) from SysDataMatrix A Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey 
										where A.CurrentStatus_MOC='C' AND A.MOC_Initialised='Y')
		ELSE
			Set @Timekey=(select CAST(B.timekey as int) from SysDataMatrix A Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey 
										where A.CurrentStatus='C')

		PRINT @Timekey

		

		IF (@UploadType='Securitization Upload')
		BEGIN
				SELECT 'Securitization Details' as TableName
				,A.UploadID
				,A.SrNo
				,A.AsOnDate
				,A.PAN
				,A.NCIF_Id AS NCIF_Id
				,A.CustomerName
				,A.CustomerACID AS AccountNo
				,A.LoanAgreementNo
				,A.BuyoutPartyLoanNo AS IndusindLoanAccountNo
				,A.TotalOutstanding
				,A.InterestReceivable AS UnrealizedInterest
				,A.PrincipalOutstanding
				,B.AssetClassName AS AssetClassification 
				,A.FinalNpaDt AS NPA_Date
				,A.DPD
				,A.SecurityValue AS SecurityAmount
				,A.AdditionalProvisionAmount
				,A.AcceleratedProvisionPercentage
				,A.SecuredStatus
				,A.Action
				
				------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
				FROM BuyoutDetails_Mod A
				INNER JOIN DimAssetClass B
				ON A.FinalAssetClassAlt_Key=B.AssetClassAlt_Key
				WHERE A.UploadID=@UniqueUploadID
				AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
		END

		ELSE IF (@UploadType='Sale to ARC Upload')
		BEGIN
				SELECT 'Sale To ARC Details' as TableName
				,UploadID
				,SrNo
				,Convert(Varchar(20),AsOnDate,103) AS AsOnDate
				,SourceSystem AS SourceSystemName
				,NCIF_ID --AS DedupIDUCICEnterPriseCIF
				,CustomerID --AS SourceSystemCIFCustomerIdentifier
				--,CustomerName
				,AccountID AS AccountNo
				,Convert(Varchar(20),DtofsaletoARC,103) AS ARCSaleDate
				,BalanceOutstanding as TotalSaleConsideration
				,POS as PrincipalConsideration
				,InterestReceivable as InterestConsideration
				,Action
				------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
				FROM SaletoARC_Mod
				WHERE UploadId=@UniqueUploadID
				AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		END

		ELSE IF (@UploadType='Write Off Data Upload')
		BEGIN
				SELECT 'WriteOff Details' as TableName
				,A.UploadId
				,A.SrNo
				,CONVERT(VARCHAR(20),A.AsOnDate,103) AS AsOnDate
				,B.SourceName AS SourceSystemName
				,A.NCIF_Id
				,A.CustomerID
				--,CustomerName
				,A.CustomerACID AS AccountID
				,CONVERT(VARCHAR(20),A.WriteOffDt,103) AS WriteOffDate
				,A.WO_PWO AS WriteOffType
				,A.WriteOffAmt AS WriteOffAmtInterest
				,A.IntSacrifice AS WriteOffAmtPrincipal
				,A.Action
				------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
				FROM AdvAcWODetail_Mod A
				INNER JOIN DimSourceSystem B
				ON A.SrcSysAlt_Key=B.SourceAlt_Key
				AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
				WHERE A.UploadId=@UniqueUploadID
				AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
		END

		ELSE IF (@UploadType='Account MOC Upload')
		BEGIN
				SELECT 'Account MOC Details' as TableName
				,A.UploadID
				, Row_Number() over(order by A.NCIF_Id) as SrNo
				--,A.AsOnDate
				--,A.PAN
				,A.NCIF_Id AS NCIF_Id
				,A.CustomerName
				,A.CustomerACID AS AccountID
				--,A.NCIF_ID  NCIF_ID
				,A.CustomerID AS CustomerID
				,S.SourceName  SourceSystem
				,A.Balance AS GrossBalance
				,A.PrincipleOutstanding  PrincipalOutstanding
				--,A.UNSERVED_INTEREST AS UnservicedInterestAmount 
				,A.IntOverdue AS UnservicedInterestAmount			----- Replace From UNSERVED_INTEREST to IntOverdue By Satwaji as on 04/09/2021 as per Bank's Requirement Change
				,A.AddlProvisionPer AS Additionalprovisionpercentage
				,A.AddlProvision  AdditionalprovisionAmount
				,B.AccProvPer AS AcceleratedProvisionPercentage
				,A.ApprRV AS SecurityValue
				,R.MocReasonName  MOCReason
				
				------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
				FROM NPA_IntegrationDetails_MOD A
				LEFT JOIN CURDAT.AcceleratedProv B ON A.CustomerACID=B.CustomerACID
				AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
				LEFT JOIN dimsourcesystem S ON S.SourceAlt_Key=A.SrcSysAlt_Key
				LEFT JOIN DimMocReason  R ON R.MocReasonAlt_Key= A.ACMOC_ReasonAlt_Key
				WHERE A.UploadID=@UniqueUploadID AND A.EffectiveFromTimeKey=@Timekey
				
		END

		ELSE IF (@UploadType='Customer MOC Upload')
		BEGIN
				SELECT 'Customer MOC Details' as TableName
				,A.UploadID
				, Row_Number() over(order by NCIF_Id) as SrNo
				--,A.AsOnDate
				,A.NCIF_Id AS DedupIDUCICEnterpriseCIF
				,A.CustomerID AS CIFCustomerIdentifier
				,A.CustomerName
				,B.AssetClassShortName AS MOC_AssetClassification
				,CONVERT(VARCHAR(10),A.MOC_NPA_Date,103) AS MOC_NPADate
					--,A.MOC_SecurityValue
				,A.AddlProvisionPer AS AdditionalProvisionPercentage
				,R.MocReasonName AS MOC_Reason
				,A.MOC_Remark AS MOC_Remark
				,A.MOCTYPE AS MOC_Type
				--,A.MOC_SOURCE
				
				------,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS ROW_NUM
				FROM NPA_IntegrationDetails_MOD A
				LEFT JOIN DimAssetClass B ON B.AssetClassAlt_Key = A.MOC_AssetClassAlt_Key
				LEFT JOIN DimMocReason  R ON R.MocReasonAlt_Key= A.MOC_ReasonAlt_Key
				WHERE A.UploadID=@UniqueUploadID
				AND A.EffectiveFromTimeKey=@Timekey
				--AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
		END							 
END
GO