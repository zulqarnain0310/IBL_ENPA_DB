CREATE TABLE [dbo].[AADHAR_VOT_DATA29112022] (
  [As_On_Date] [varchar](100) NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerName] [varchar](500) NULL,
  [PAN] [varchar](10) MASKED WITH (FUNCTION = 'default()') NULL,
  [IsNPA] [varchar](50) NULL,
  [WriteOffDate] [date] NULL,
  [IsARC_Sale] [varchar](50) NULL,
  [IsSuitFiled] [varchar](50) NULL,
  [IsOTS] [varchar](50) NULL,
  [IsFraud] [varchar](50) NULL,
  [AADHAR_NO] [varchar](120) NULL,
  [KYCID] [varchar](120) NULL
)
ON [PRIMARY]
GO