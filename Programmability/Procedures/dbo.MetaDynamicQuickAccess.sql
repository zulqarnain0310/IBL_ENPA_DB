SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[MetaDynamicQuickAccess]
	 @MenuId Int=6668,
	 @TimeKey INT=24528,
	 @Mode TINYINT=2

 AS 
BEGIN

---------------------------------Added by Vijay 
--IF @MenuId IN (640)
--	BEGIN
	
--	SELECT 'MetaGrid'  AS TableName, 'BranchCode' ControlName, 'Branch Code' Label
--	UNION
--	SELECT 'MetaGrid'  AS TableName, 'CustomerId' ControlName, 'Customer ID' Label
--	UNION
--	SELECT 'MetaGrid'  AS TableName, 'CustomerName' ControlName, 'Customer Name' Label
--	--UNION
--	--SELECT 'MetaGrid'  AS TableName, 'ProposalID' ControlName, 'Proposal ID' Label

--	END



--Else
----------------------------------------
--Begin
SELECT 'MetaGrid'  AS TableName,A.ControlName, B.*
					FROM MetaDynamicScreenField A 
						INNER JOIN MetaDynamicGrid B
							ON A.ControlId=B.ControlId
					WHERE MENUID=@MENUID
						AND ISNULL(ValidCode,'N')='Y' 
					ORDER BY EntityKey

--End
	SELECT  'ScreenDetail' TableName,MenuCaption ,MenuId,NonAllowOperation,DeptGroupCode,EnableMakerChecker,ResponseTimeDisplay,AccessLevel
				,CASE WHEN ISNULL(GridApplicable,'N')='Y' THEN 1 ELSE 0 END GridApplicable
				,CASE WHEN ISNULL(Accordian,'N')='Y' THEN 1 ELSE 0 END Accordian
				
				, convert(varchar(10),getdate(),103) [CURDATE]
			FROM SysCRisMacMenu WHERE MenuId= @MenuId


			

	--Get Quick Access Fields Meta


				SELECT	'QuickAccessMeta' AS TableName
						,ControlID
						,ParentcontrolID
						,Label
						,'DynamicMaster_'+REPLACE(Label,' ','') + '_Msg'  AS FieldMessage
						,ControlName ColumnName
						,ControlType
						----------------------------Added by Vijay ----
						--,CASE WHEN ControlName='BranchCode' AND ControlType='shutter' THEN 'f2autocomplete' 
						--	WHEN ControlName <> 'BranchCode' AND ControlType='shutter' THEN 'text'	
						--	ELSE ControlType END ControlType 
						-----------------------
						,AutoCmpltMinLength
						,Col_sm
						,Col_lg
						,Col_md
						,SourceTable
						,DisplayRowOrder
						,DisplayColumnOrder
						,SourceColumn
						,ReferenceTableFilter
						,ISNULL(ReferenceTable,'NA') AS ReferenceTable, ISNULL(ReferenceColumn,'NA') AS ReferenceColumn
						,RefColumnValue
						,ReferenceTableCond
						,BaseColumnType
						,[DataType]
						,ISNULL(DataMinLength,0) as DataMinLength
						,ISNULL(DataMaxLength,0) as DataMaxLength
						,ControlName
						,DisAllowedChar
						,AllowedChar
						,OnBlur
						,OnBlurParameter
						,OnClick
						,OnClickParameter
						,OnChange
						,OnChangeParameter
						,OnKeyPress
						,OnKeyPressParameter
						,OnFormLoad
						,OnFormLoadParameter
						,DefaultValue
						,isnull(Class,'') Class
						,isnull(Style,'') Style
						,ControlName +'Filter' as ControlNameFilter
						,''as ControlNameFrom
						,'' as  ControlNameTo
						,0 as IsBetween 
				FROM MetaDynamicScreenField B
					--WHERE MenuId=@MenuId --and IsQuickSearch='Y'  //commented 28062022
					WHERE MenuId=@MenuId and IsQuickSearch='Y'

						ORDER BY DisplayRowOrder, DisplayColumnOrder 


				SELECT 'QuickAccessMaster'  AS TableName ,A.ControlId,MasterTable

				FROM MetaDynamicScreenField A 
						INNER JOIN METADYNAMICMASTER B
					ON A.CONTROLID=B.CONTROLID
				WHERE MENUID=@MENUID  --and IsQuickSearch='Y'


		--- Static SP ---------

			SELECT 	'StaticSP' AS TableName,			
					SSP.ControlID,SPName,ClientSideParams,ServerSideParams
				FROM [MetaDynamicCallStaticSP] SSP
				   INNER JOIN MetaDynamicScreenField FLD
					 ON SSP.ControlID = FLD.ControlID AND FLD.MenuID = @MenuId
		------------------------------------

END
GO