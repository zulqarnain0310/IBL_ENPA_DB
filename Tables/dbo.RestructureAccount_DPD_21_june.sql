CREATE TABLE [dbo].[RestructureAccount_DPD_21_june] (
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [AccountEntityID] [int] NOT NULL,
  [CustomerACID] [varchar](20) NULL,
  [MaxDPD] [int] NOT NULL,
  [TimeKey] [int] NOT NULL,
  [NCIF_Id_dpd] [int] NOT NULL,
  [dpd_date] [varchar](10) NOT NULL
)
ON [PRIMARY]
GO