CREATE TABLE [dbo].[SaletoARC] (
  [EntityKey] [int] IDENTITY,
  [SourceSystem] [varchar](30) NULL,
  [CustomerID] [varchar](max) NULL,
  [CustomerName] [varchar](max) NULL,
  [AccountID] [varchar](16) NULL,
  [BalanceOutstanding] [decimal](18, 2) NULL,
  [POS] [decimal](18, 2) NULL,
  [InterestReceivable] [decimal](18, 2) NULL,
  [DtofsaletoARC] [date] NULL,
  [DateofApproval] [date] NULL,
  [AmountSold] [decimal](18, 2) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](100) NULL,
  [DateCreated] [datetime] NULL,
  [ModifyBy] [varchar](100) NULL,
  [DateModified] [date] NULL,
  [ApprovedBy] [varchar](100) NULL,
  [DateApproved] [datetime] NULL,
  [D2Ktimestamp] [timestamp],
  [ChangeFields] [varchar](100) NULL,
  [PoolID] [varchar](max) NULL,
  [PoolName] [varchar](max) NULL,
  [AsOnDate] [date] NULL,
  [NCIF_ID] [varchar](max) NULL,
  [Action] [char](1) NULL,
  [SrNo] [int] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO