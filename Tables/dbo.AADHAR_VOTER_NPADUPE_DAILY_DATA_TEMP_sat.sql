CREATE TABLE [dbo].[AADHAR_VOTER_NPADUPE_DAILY_DATA_TEMP_sat] (
  [As_On_Date] [varchar](100) NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerName] [varchar](500) NULL,
  [PAN] [varchar](10) NULL,
  [IsNPA] [varchar](50) NULL,
  [WriteOffDate] [date] NULL,
  [IsARC_Sale] [varchar](50) NULL,
  [IsSuitFiled] [varchar](50) NULL,
  [IsOTS] [varchar](50) NULL,
  [IsFraud] [varchar](50) NULL,
  [MaxDPD] [varchar](50) NULL,
  [IsRestructured] [varchar](120) NULL,
  [RestructureDt] [date] NULL,
  [AADHAR_NO] [varchar](120) NULL,
  [KYCID] [varchar](120) NULL,
  [RECEIVED_ON] [date] NULL
)
ON [PRIMARY]
GO