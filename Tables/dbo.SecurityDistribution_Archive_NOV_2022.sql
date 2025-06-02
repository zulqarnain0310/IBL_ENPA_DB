CREATE TABLE [dbo].[SecurityDistribution_Archive_NOV_2022] (
  [AsOnDate] [date] NULL,
  [NCIF_ID] [varchar](100) NULL,
  [CustomerId] [varchar](50) NULL,
  [CollateralID] [varchar](100) NULL,
  [CustomerExposer] [decimal](30, 5) NULL,
  [CollTotal] [decimal](30, 5) NULL,
  [CollWiseCustExposure] [decimal](30, 5) NULL,
  [AppPER] [decimal](10, 5) NULL,
  [AppSecurity] [decimal](30, 5) NULL,
  [CustomerAcID] [varchar](50) NULL,
  [AccountPOS] [decimal](30, 5) NULL,
  [AccountSecPer] [decimal](10, 5) NULL,
  [AccountAppSecurity] [decimal](30, 5) NULL
)
ON [PRIMARY]
GO