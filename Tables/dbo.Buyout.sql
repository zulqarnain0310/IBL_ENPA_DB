CREATE TABLE [dbo].[Buyout] (
  [PAN] [varchar](50) MASKED WITH (FUNCTION = 'default()') NULL,
  [Customer Name] [varchar](100) NULL,
  [Account No] [varchar](50) NULL,
  [Loan Agreement No] [varchar](50) NULL,
  [Indusind Loan Account No] [varchar](50) NULL,
  [Total Outstanding] [varchar](50) NULL,
  [Unrealized Interest] [varchar](50) NULL,
  [Principal Outstanding] [varchar](50) NULL,
  [Asset Classification ] [varchar](50) NULL,
  [NPA Date] [varchar](50) NULL,
  [DPD] [varchar](50) NULL,
  [Security Amount] [varchar](50) NULL,
  [Acc Prov] [varchar](50) NULL
)
ON [PRIMARY]
GO