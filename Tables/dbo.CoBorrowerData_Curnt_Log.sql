CREATE TABLE [dbo].[CoBorrowerData_Curnt_Log] (
  [AsOnDate] [date] NULL,
  [SourceSystemName_PrimaryAccount] [varchar](40) NULL,
  [NCIFID_PrimaryAccount] [varchar](40) NULL,
  [CustomerId_PrimaryAccount] [varchar](40) NULL,
  [CustomerACID_PrimaryAccount] [varchar](4000) NULL,
  [NCIFID_COBORROWER] [varchar](40) NULL,
  [AcDegFlg] [varchar](1) NULL,
  [AcDegDate] [date] NULL,
  [AcUpgFlg] [varchar](1) NULL,
  [AcUpgDate] [date] NULL,
  [Flag] [varchar](10) NULL,
  [Operation] [varchar](20) NULL,
  [Changetime] [datetime] NULL,
  [UserName] [varchar](50) NULL
)
ON [PRIMARY]
GO