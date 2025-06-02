CREATE TABLE [dbo].[DEDUPE_D2KEXPORT_BKP_Freshdata] (
  [UUID] [numeric] NULL,
  [ENTERPRISE_CIF] [numeric] NULL,
  [APPLICATION_CIF] [varchar](250) NULL,
  [APPLICATION_SOURCE] [varchar](250) NULL,
  [CUSTOMER_NAME] [varchar](250) NULL,
  [PAN_NO] [varchar](250) NULL,
  [AADHAR_NO] [varchar](100) NULL,
  [VOTER_ID] [varchar](255) NULL,
  [KYCTYPE] [varchar](255) NULL,
  [KYCID] [varchar](100) NULL,
  [DATA_TYPE_FLAG] [varchar](1) NULL,
  [RECEIVED_FLAG] [varchar](1) NULL,
  [INSERTTIMESTAMP] [date] NULL,
  [RECEIVED_ON] [date] NULL
)
ON [PRIMARY]
GO