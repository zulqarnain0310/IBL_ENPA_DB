CREATE TABLE [dbo].[NPA_MOVEMENT_UCIF_WISE] (
  [SOURCE_SYSTEM] [varchar](50) NULL,
  [NCIF_ID] [varchar](20) NULL,
  [CIF_ID] [varchar](20) NULL,
  [ACCOUNT_NO] [varchar](20) NULL,
  [CustomerName] [varchar](50) NULL,
  [Opening_POS] [varchar](50) NULL,
  [Fresh_NPA_Slippages] [varchar](50) NULL,
  [Increase_in_existing] [varchar](50) NULL,
  [Upgrades] [varchar](50) NULL,
  [Write_off_] [varchar](50) NULL,
  [Sale_to_ARC_Others] [varchar](50) NULL,
  [Recovery] [varchar](50) NULL,
  [Closing_POS] [varchar](50) NULL,
  [SCHEME_CODE] [varchar](20) NULL,
  [SEGMENT] [varchar](20) NULL,
  [MOVEMENT_SEGMENT] [varchar](20) NULL
)
ON [PRIMARY]
GO