CREATE TABLE [dbo].[Restructure_Upgrade_Output] (
  [NCIF] [varchar](100) NULL,
  [CIF] [varchar](20) NULL,
  [Account_Number] [varchar](20) NULL,
  [Source_System] [varchar](50) NULL,
  [Name] [varchar](500) NULL,
  [Type_of_Restructuring] [varchar](50) NULL,
  [POS] [decimal](16, 2) NULL,
  [Int_Overdue] [decimal](16, 2) NULL,
  [Balance] [decimal](16, 2) NULL,
  [Upgrade_Elligibility_Date] [nvarchar](30) NULL
)
ON [PRIMARY]
GO