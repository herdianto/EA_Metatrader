//+------------------------------------------------------------------+
//|                                              Moving Averages.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

input double MaximumRisk        = 0.02;    // Maximum Risk in percentage
input double DecreaseFactor     = 3;       // Descrease factor
input int    MovingPeriod       = 12;      // Moving Average period
input int    MovingShift        = 6;       // Moving Average shift
//---
bool   lower = false;
bool   lower_35 = false;
bool   lower_30 = false;
bool   upper = false;
bool   upper_65 = false;
bool   upper_70 = false;

int    ExtHandle=0;
double iRsi_handle;
int    iRsi_per=14;
bool   ExtHedging=false;
CTrade ExtTrade;
double iRSIBuffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
  //SendNotification("robot started!");
  int FillingMode=(int)SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
  Comment (
      "Filling Mode: ",FillingMode,
      "\nSymbol      : ", SymbolInfoString(_Symbol, SYMBOL_DESCRIPTION),         
      "\nAccount Company: ", AccountInfoString(ACCOUNT_COMPANY),
      "\nAccount Server : ", AccountInfoString(ACCOUNT_SERVER)); 

//--- prepare trade class to control positions if hedging mode is active
/*
   ExtHedging=((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   ExtTrade.SetExpertMagicNumber(MA_MAGIC);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(Symbol());
*/
//--- Moving Average indicator
/*
   ExtHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
 */
   //iRsi_handle=iRSI(_Symbol,PERIOD_CURRENT,100,PRICE_CLOSE);
   CopyBuffer(iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE),0,0,1,iRSIBuffer);
   iRsi_handle = iRSIBuffer[0];
   //Comment (iRsi_handle);

   printf("current RSI value="+iRsi_handle);
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//---
   CopyBuffer(iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE),0,0,1,iRSIBuffer);
   iRsi_handle = iRSIBuffer[0];
   
   //buy signal
   if(iRsi_handle < 35 && lower_35 == false){
      SendNotification("RSI lower than 35");
      lower_35 = true;
   }else{
      lower_35 = false;
   }
   
   if(iRsi_handle < 30 && lower_30 == false){
      SendNotification("RSI lower than 30");
      lower_30 = true;
   }else{
      lower_30 = false;
   }
   
   if(iRsi_handle < 30 && lower == false){
      lower = true;
   }else{
      if(lower == true && iRsi_handle >= 30)
        {
         SendNotification("I think you should place buy now :)");
         lower = false;
        }
   }
   
   //sell signal
   if(iRsi_handle > 65 && upper_65 == false){
      SendNotification("RSI bigger than 35");
      upper_65 = true;
   }else{
      upper_65 = false;
   }
   
   if(iRsi_handle > 70 && upper_70 == false){
      SendNotification("RSI bigger than 70");
      upper_70 = true;
   }else{
      upper_70 = false;
   }
   
   if(iRsi_handle > 70 && upper == false){
      upper = true;
   }else{
      if(upper == true && iRsi_handle <= 70)
        {
         SendNotification("I think you should place sell now :)");
         upper = false;
        }
   }
//---
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
