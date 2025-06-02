CREATE TABLE [dbo].[CoBorrowerData_HistORY_Archive_JUL_2024] (
  [AsOnDate] [date] NULL,
  [SourceSystemName_PrimaryAccount] [varchar](40) NULL,
  [NCIFID_PrimaryAccount] [varchar](40) NULL,
  [CustomerId_PrimaryAccount] [varchar](40) NULL,
  [CustomerACID_PrimaryAccount] [varchar](40) NULL,
  [NCIFID_COBORROWER] [varchar](40) NULL,
  [AcDegFlg] [char](1) NULL,
  [AcDegDate] [date] NULL,
  [AcUpgFlg] [char](1) NULL,
  [AcUpgDate] [date] NULL,
  [Flag] [varchar](10) NULL,
  [EFFECTIVEFROMTIMEKEY] [int] NULL,
  [EFFECTIVETOTIMEKEY] [int] NULL,
  [DATECREATED] [date] NULL
)
ON [PRIMARY]
GO