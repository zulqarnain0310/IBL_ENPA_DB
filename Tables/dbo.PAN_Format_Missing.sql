CREATE TABLE [dbo].[PAN_Format_Missing] (
  [ENTERPRISE_CIF] [varchar](20) NULL,
  [CLIENT_ID] [varchar](20) NULL,
  [CUSTOMER_NAME] [varchar](80) NULL,
  [ACCOUNT_NUMBER] [varchar](50) NULL,
  [PAN] [varchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
  [SrcAppAlt_Key] [int] NULL
)
ON [PRIMARY]
GO