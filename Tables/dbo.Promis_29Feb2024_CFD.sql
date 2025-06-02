CREATE TABLE [dbo].[Promis_29Feb2024_CFD] (
  [Date] [date] NULL,
  [SourceName] [varchar](50) NULL,
  [CIF_ID] [varchar](20) NULL,
  [Ent_Cif] [varchar](100) NULL,
  [Currency] [varchar](3) NOT NULL,
  [FORACID] [varchar](20) NULL,
  [NPA_DATE] [date] NULL,
  [Sanction_Limit] [decimal](18, 2) NULL,
  [Drawing_Power] [decimal](16, 2) NULL,
  [Date_of_Overdrawing] [date] NULL,
  [Amount_Overdrawn] [decimal](16, 2) NULL,
  [DPD_due_to_Overdrawn] [int] NULL,
  [Date_of_Limit_Expiry] [date] NULL,
  [DPD_due_to_Limit_Expiry] [smallint] NULL,
  [Amt_of_Unserviced_interest] [decimal](16, 2) NULL,
  [DPD_Unserviced_Interest] [int] NULL,
  [TOD_Utilization] [decimal](16, 2) NULL,
  [Credit_Tran_in_past_120_days] [decimal](16, 2) NULL,
  [DPD_Loans] [int] NULL,
  [DPD_Loans_Overdue] [int] NULL,
  [NPA Flag] [varchar](1) NOT NULL,
  [Provision_Amount] [decimal](16, 2) NULL
)
ON [PRIMARY]
GO