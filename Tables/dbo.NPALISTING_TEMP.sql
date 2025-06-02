CREATE TABLE [dbo].[NPALISTING_TEMP] (
  [SourceName] [varchar](50) NULL,
  [SolId] [varchar](20) NULL,
  [Segment] [varchar](100) NULL,
  [ProductCode] [varchar](50) NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerACID] [varchar](20) NULL,
  [IsFunded] [char](1) NULL,
  [CustomerName] [varchar](500) NULL,
  [NCIF_NPA_Date] [date] NULL,
  [AssetClassName] [varchar](50) NULL,
  [Balance] [decimal](16, 2) NULL,
  [IntOverdue] [decimal](16, 2) NULL,
  [PrincipleOutstanding] [decimal](16, 2) NULL,
  [SecurityValue] [decimal](24) NULL,
  [SecuredAmt] [decimal](16, 2) NULL,
  [UnSecuredAmt] [decimal](16, 2) NULL,
  [TotalProvision] [decimal](16, 2) NULL,
  [PAN] [varchar](10) NULL,
  [Reportingdate] [date] NULL
)
ON [PRIMARY]
GO