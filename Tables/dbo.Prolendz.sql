﻿CREATE TABLE [dbo].[Prolendz] (
  [System] [varchar](50) NULL,
  [Cross_Dedupe_Match_Id] [varchar](50) NULL,
  [Customer_Code] [varchar](50) NULL,
  [Customer_Name] [varchar](100) NULL,
  [Deal_No] [varchar](50) NULL,
  [Sanc_Limit] [varchar](50) NULL,
  [Outstanding] [varchar](50) NULL,
  [Principle_Outstanding] [varchar](50) NULL,
  [NPA_Status] [varchar](50) NULL,
  [NPA_Date] [varchar](50) NULL,
  [Settlement_Status] [varchar](50) NULL,
  [Write_Off_Flag] [char](1) NULL,
  [Group_Id] [varchar](50) NULL,
  [Group_Desc] [varchar](50) NULL,
  [Segment] [varchar](50) NULL,
  [Sub_Segment] [varchar](50) NULL,
  [PAN] [varchar](50) MASKED WITH (FUNCTION = 'default()') NULL,
  [Aadhaar_UID] [varchar](50) NULL,
  [Scheme_Code] [varchar](50) NULL,
  [Scheme_Code_Desc] [varchar](50) NULL,
  [Drawing_Power] [decimal](9, 2) NULL,
  [DPD] [smallint] NULL,
  [DPD_Interest_Not_Serviced] [smallint] NULL,
  [DPD_OverDrawn] [smallint] NULL,
  [DPD_Renewals] [smallint] NULL,
  [Overdue] [decimal](9, 2) NULL
)
ON [PRIMARY]
GO