CREATE TABLE [dbo].[CoBorrowerData_Curnt] (
  [AsOnDate] [date] NULL,
  [SourceSystemName_PrimaryAccount] [varchar](40) NULL,
  [NCIFID_PrimaryAccount] [varchar](40) NULL,
  [CustomerId_PrimaryAccount] [varchar](40) NULL,
  [CustomerACID_PrimaryAccount] [varchar](4000) NULL,
  [NCIFID_COBORROWER] [varchar](40) NULL,
  [AcDegFlg] [char](1) NULL,
  [AcDegDate] [date] NULL,
  [AcUpgFlg] [char](1) NULL,
  [AcUpgDate] [date] NULL,
  [Flag] [varchar](10) NULL
)
ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[trgCoBorrowerData_CurntDelete]
ON [dbo].[CoBorrowerData_Curnt]
FOR Delete
AS
   INSERT INTO CoBorrowerData_Curnt_Log (AsOnDate,SourceSystemName_PrimaryAccount,NCIFID_PrimaryAccount,
						CustomerId_PrimaryAccount,CustomerACID_PrimaryAccount
						,NCIFID_COBORROWER,AcDegFlg,AcDegDate,AcUpgFlg,AcUpgDate,Flag,Operation,Changetime,UserName)
   SELECT AsOnDate,SourceSystemName_PrimaryAccount,NCIFID_PrimaryAccount,
						CustomerId_PrimaryAccount,CustomerACID_PrimaryAccount
						,NCIFID_COBORROWER,AcDegFlg,AcDegDate,AcUpgFlg,AcUpgDate,Flag, 'DELETE', GETDATE(), SUSER_NAME()
   FROM DELETED;
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[trgCoBorrowerData_CurntInsert]
ON [dbo].[CoBorrowerData_Curnt]
FOR INSERT
AS
   INSERT INTO CoBorrowerData_Curnt_Log (AsOnDate,SourceSystemName_PrimaryAccount,NCIFID_PrimaryAccount,
						CustomerId_PrimaryAccount,CustomerACID_PrimaryAccount
						,NCIFID_COBORROWER,AcDegFlg,AcDegDate,AcUpgFlg,AcUpgDate,Flag,Operation,Changetime,UserName)
   SELECT AsOnDate,SourceSystemName_PrimaryAccount,NCIFID_PrimaryAccount,
						CustomerId_PrimaryAccount,CustomerACID_PrimaryAccount
						,NCIFID_COBORROWER,AcDegFlg,AcDegDate,AcUpgFlg,AcUpgDate,Flag, 'INSERT', GETDATE(), SUSER_NAME()
   FROM INSERTED;
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[trgCoBorrowerData_CurntUPDATE]
ON [dbo].[CoBorrowerData_Curnt]
FOR UPDATE
AS
   INSERT INTO CoBorrowerData_Curnt_Log (AsOnDate,SourceSystemName_PrimaryAccount,NCIFID_PrimaryAccount,
						CustomerId_PrimaryAccount,CustomerACID_PrimaryAccount
						,NCIFID_COBORROWER,AcDegFlg,AcDegDate,AcUpgFlg,AcUpgDate,Flag,Operation,Changetime,UserName)
   SELECT AsOnDate,SourceSystemName_PrimaryAccount,NCIFID_PrimaryAccount,
						CustomerId_PrimaryAccount,CustomerACID_PrimaryAccount
						,NCIFID_COBORROWER,AcDegFlg,AcDegDate,AcUpgFlg,AcUpgDate,Flag, 'UPDATE', GETDATE(), SUSER_NAME()
   FROM INSERTED;
GO

DISABLE TRIGGER [dbo].[trgCoBorrowerData_CurntDelete] ON [dbo].[CoBorrowerData_Curnt]
GO

DISABLE TRIGGER [dbo].[trgCoBorrowerData_CurntInsert] ON [dbo].[CoBorrowerData_Curnt]
GO

DISABLE TRIGGER [dbo].[trgCoBorrowerData_CurntUPDATE] ON [dbo].[CoBorrowerData_Curnt]
GO