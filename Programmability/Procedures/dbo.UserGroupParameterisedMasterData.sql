SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[UserGroupParameterisedMasterData] 
	@timekey INT
AS
BEGIN
	PRINT 'START'
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
				FROM metaUserFieldDetail WHERE FrmName ='frmUserGroup'
					  
				 Select  EntityKey, MenuTitleId,DataSeq, ISNULL(MenuId,0) MenuId ,ISNULL(ParentId,0) ParentId,MenuCaption, ActionName,BusFld
					From SysCRisMacMenu WHERE Visible=1
					Order by MenuTitleID, DataSeq

END








GO