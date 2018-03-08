//+------------------------------------------------------------------+
//|                                              Moving Averages.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


input double MaximumRisk        = 0.02;    // Maximum Risk in percentage
input double DecreaseFactor     = 3;       // Descrease factor
input int    MovingPeriod       = 12;      // Moving Average period
input int    MovingShift        = 6;       // Moving Average shift
//---

//Transaction indicator
double test=0;

//iOsMA
double iOsMA_handle;
int    iOsMA_fast_per=12;
int    iOsMA_slow_per=26;
int    iOsMA_signal=9;
double iOsMABuffer[];

//iRSI
double iRsi_handle;
int    iRsi_per=14;
bool   ExtHedging=false;
double iRSIBuffer[];
bool   lower = false;
bool   lower_35 = false;
bool   lower_30 = false;
bool   upper = false;
bool   upper_65 = false;
bool   upper_70 = false;
int    iRSISellLimit = 70;
int    iRSIBuyLimit = 30;

//new minute checking
datetime PreviousTime;
int tickMinutes = 1;

//new bar checking
static datetime Old_Time;
datetime New_Time[1];
bool IsNewBar=false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
  Print("robot started!");
  SendNotification("robot started!");
  int FillingMode=(int)SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
  Comment (
      "Filling Mode: ",FillingMode,
      "\nSymbol      : ", SymbolInfoString(_Symbol, SYMBOL_DESCRIPTION),         
      "\nAccount Company: ", AccountInfoString(ACCOUNT_COMPANY),
      "\nAccount Server : ", AccountInfoString(ACCOUNT_SERVER)); 

   //Prepare iRSI
   CopyBuffer(iRSI(_Symbol,PERIOD_CURRENT,iRsi_per,PRICE_CLOSE),0,0,1,iRSIBuffer);
   iRsi_handle = iRSIBuffer[0];
   //TO DO: handle iRSI error
   
   //Prepare iOsMA
   CopyBuffer(iOsMA(_Symbol,PERIOD_CURRENT,iOsMA_fast_per, iOsMA_slow_per, iOsMA_signal,PRICE_CLOSE),0,0,1,iOsMABuffer);
   iOsMA_handle = iOsMABuffer[0];
   //TO DO: handle iOsMA error
   
   //Prepare new minute checking
   PreviousTime = TimeCurrent();
   //printf("Current Time= "+PreviousTime);
   //printf("current RSI value="+iRsi_handle);
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
  //for new bar checking
  int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
  if(copied>0){ // ok, the data has been copied successfully
   if(Old_Time!=New_Time[0]){ // if old time isn't equal to new bar time
      IsNewBar=true;  // if it isn't a first call, the new bar has appeared
      //if(MQL5InfoInteger(MQL5_DEBUGGING)) 
      //Print("We have new bar here ",New_Time[0]," old time was ",Old_Time, " latest close price is: ", getLatestClosePrice());
      Old_Time=New_Time[0];            // saving bar time
      
      //iOsMA Indicator
      CopyBuffer(iOsMA(_Symbol,PERIOD_CURRENT,iOsMA_fast_per, iOsMA_slow_per, iOsMA_signal,PRICE_CLOSE),0,0,1,iOsMABuffer);
      iOsMA_handle = iOsMABuffer[0];
      //Print("iOsMA value :",iOsMA_handle);
   }
  }
  else{
   Alert("Error in copying historical times data, error =",GetLastError());
   ResetLastError();
   return;
  }
  
  //if(PreviousTime <= TimeCurrent() - (tickMinutes * 60)){
  if(IsNewBar==true){
   PreviousTime = TimeCurrent();
   
   //iOsMA Indicator
   CopyBuffer(iOsMA(_Symbol,PERIOD_CURRENT,iOsMA_fast_per, iOsMA_slow_per, iOsMA_signal,PRICE_CLOSE),0,0,1,iOsMABuffer);
   iOsMA_handle = iOsMABuffer[0];
   //Print("iOsMA value :",iOsMA_handle);
      
   //iRSI Indicator
   CopyBuffer(iRSI(_Symbol,PERIOD_CURRENT,iRsi_per,PRICE_CLOSE),0,0,1,iRSIBuffer);
   iRsi_handle = iRSIBuffer[0];
   
   //buy signal
   //printf(TimeCurrent()+" "+lower_35);
   if(iRsi_handle < 35){
      if(lower_35 == false){
         //SendNotification("RSI lower than 35 : "+TimeCurrent());
         lower_35 = true;
      }else{
         
      }
   }else{
      lower_35 = false;
   }
   
   if(iRsi_handle < 30 && lower_30 == false){
      if(lower_30 == false){
         //SendNotification("RSI lower than 30 : "+TimeCurrent());
         lower_30 = true;
      }else{
         
      } 
   }else{
      lower_30 = false;
   }
   
   if(iRsi_handle < iRSIBuyLimit && lower == false){
      lower = true;
   }
   if(lower == true && iRsi_handle >= iRSIBuyLimit){
      //SendNotification("RSI rises up from 31 : "+TimeCurrent());
      Print("prepare to buy, RSI: ",iRsi_handle);
      lower = false;
   }
   
   
   //sell signal
   if(iRsi_handle > 65 && upper_65 == false){
      if(upper_65 == false){
         //SendNotification("RSI bigger than 65 : "+TimeCurrent());
         upper_65 = true;
      }else{
         
      }
   }else{
      upper_65 = false;
   }
   
   if(iRsi_handle > 70 && upper_70 == false){
      if(upper_70 == false){
         //SendNotification("RSI bigger than 70 : "+TimeCurrent());
         upper_70 = true;
      }else{
         
      }   
   }else{
      upper_70 = false;
   }
   
   if(iRsi_handle > iRSISellLimit && upper == false){
      upper = true;
   }
   
   if(upper == true && iRsi_handle <= iRSISellLimit){
     //SendNotification("RSI falls down from 71 : "+TimeCurrent());
     Print("prepare to sell, RSI: ",iRsi_handle);
     upper = false;
   }
   
  }
  IsNewBar=false;
//---
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+

double getLatestClosePrice(){
   // Rates Structure for the data of the Last incomplete BAR
   MqlRates BarData[2]; 
   CopyRates(Symbol(), Period(), 0, 2, BarData); // Copy the data of last incomplete BAR

   // Copy latest close price.
   return BarData[0].close;
}