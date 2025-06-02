CREATE TABLE [dbo].[d_acc_prov] (
  [As On Date] [varchar](50) NULL,
  [Dedupe ID - UCIC - Enterprise CIF] [varchar](50) NULL,
  [Source System CIF - Customer Identifier] [varchar](50) NULL,
  [Source System] [varchar](50) NULL,
  [Customer Name] [varchar](50) NULL,
  [Account ID] [varchar](50) NULL,
  [Gross Balance] [varchar](50) NULL,
  [Principal Outstanding] [varchar](50) NULL,
  [Un-serviced Interest Amount] [varchar](50) NULL,
  [Additional provision percentage – manual (incremental %)] [varchar](50) NULL,
  [Additional provision Amount- manual (incremental)] [varchar](50) NULL,
  [Accelerated provision amount- manual (total provision)] [varchar](50) NULL,
  [MOC Reason] [varchar](50) NULL
)
ON [PRIMARY]
GO