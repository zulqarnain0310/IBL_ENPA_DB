CREATE TABLE [dbo].[DateOfWriteOff] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [UploadID] [int] NULL,
  [AccountID] [varchar](max) NULL,
  [CustomerID] [varchar](max) NULL,
  [WriteOffDt] [date] NULL,
  [WO_PWO] [char](3) NULL,
  [WriteOffAmt] [decimal](18, 2) NULL,
  [IntSacrifice] [decimal] NULL,
  [Action] [varchar](5) NULL,
  [DateOfApproval] [varchar](max) NULL,
  [filname] [varchar](max) NULL,
  [ErrorMessage] [varchar](max) NULL,
  [ErrorinColumn] [varchar](max) NULL,
  [Srnooferroneousrows] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO