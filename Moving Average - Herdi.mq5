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
input int    EA_Magic=12345;   // EA Magic Number
//---

//Validation
//1. add acct validation (real/demo): https://www.mql5.com/en/articles/481

//Transaction indicator
MqlTradeRequest request={0};
MqlTradeResult result={0};
MqlDateTime dt;
CTrade  trade;
bool bord=false, sord=false;
datetime t[];
bool   iRSIReady_long=false;
bool   iRSIReady_short=false;
bool   iOsMAReady=false;
ulong  tickets[];
int i =0;
ulong    ticket; 
double   openPrice; 
double   volume; 
datetime timeSetup; 
string   symbol; 
string   type;
double   currentPrice;
double   bid;
double   ask;
int      stop_level;
double   price_level; 
double   currentProfit;
double   sl;
double   tp;


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
int    iRSISellLimit = 65;
int    iRSIBuyLimit = 35;

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
int OnInit(void){
  //--- make sure that the account is demo 
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL) 
     { 
      Alert("Script operation is not allowed on a live account!"); 
      return 0; 
     } 
  int positionTotal = PositionsTotal();
  ArrayResize(tickets,positionTotal);
  for(int x=0; x<positionTotal; x++){
     tickets[x] = PositionGetTicket(x);
     ticket=PositionGetTicket(x);// ticket of the position
     symbol=PositionGetString(POSITION_SYMBOL); // symbol 
     openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
     type=EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
     volume=PositionGetDouble(POSITION_VOLUME);  
     bid=SymbolInfoDouble(symbol,SYMBOL_BID);
     ask=SymbolInfoDouble(symbol,SYMBOL_ASK);
     stop_level=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
     currentProfit = PositionGetDouble(POSITION_PROFIT);
     price_level = stop_level*SymbolInfoDouble(symbol,SYMBOL_POINT);
  }
  //bool closePosition = trade.PositionClose(ticket,1);
  bool a=IsFillingTypeAllowed(_Symbol, 0);
  Print("robot started!");
  //SendNotification("robot started!");
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
      //CopyBuffer(iOsMA(_Symbol,PERIOD_CURRENT,iOsMA_fast_per, iOsMA_slow_per, iOsMA_signal,PRICE_CLOSE),0,0,1,iOsMABuffer);
      //iOsMA_handle = iOsMABuffer[0];
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
      
   //iRSI Indicator
   CopyBuffer(iRSI(_Symbol,PERIOD_CURRENT,iRsi_per,PRICE_CLOSE),0,0,1,iRSIBuffer);
   iRsi_handle = iRSIBuffer[0];
   
   //buy signal
   if(iRsi_handle < 35){
      if(lower_35 == false){
         Print("RSI lower than 35 : ",TimeCurrent());
         lower_35 = true;
      }else{
         
      }
   }else{
      lower_35 = false;
   }
   
   if(iRsi_handle < 30 && lower_30 == false){
      if(lower_30 == false){
         Print("RSI lower than 30 : ",TimeCurrent());
         lower_30 = true;
      }else{
         
      } 
   }else{
      lower_30 = false;
   }
   
   if(iRsi_handle < iRSIBuyLimit && lower == false){
      lower = true;
      SendNotification("prepare to open position - long, RSI: "+iRsi_handle);
      Print("prepare to open position - long, RSI: ",iRsi_handle);
      iRSIReady_long = true;
   }
   
   if(lower == true && iRsi_handle >= iRSIBuyLimit){
      //SendNotification("prepare to open position - long, RSI: "+iRsi_handle);
      //Print("prepare to open position - long, RSI: ",iRsi_handle);
      //iRSIReady_long = true;
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
       SendNotification("prepare to open position - short, RSI: "+iRsi_handle);
       Print("prepare to open position - short, RSI: ",iRsi_handle);
       iRSIReady_short = true;
       upper = true;
   }
   
   
   if(upper == true && iRsi_handle <= iRSISellLimit){
     //SendNotification("prepare to open position - short, RSI: "+iRsi_handle);
     //Print("prepare to open position - short, RSI: ",iRsi_handle);
     //iRSIReady_short = true;
     upper = false;
   }
   
   
  }
  
  //iOsMA Indicator
  CopyBuffer(iOsMA(_Symbol,PERIOD_CURRENT,iOsMA_fast_per, iOsMA_slow_per, iOsMA_signal,PRICE_CLOSE),0,0,2,iOsMABuffer);
  iOsMA_handle = iOsMABuffer[0];
  if(iRSIReady_short){
      if(iOsMABuffer[1]<iOsMABuffer[0]){
         iRSIReady_short = false;
         SendNotification("Place short position now, price = "+getLatestClosePrice());
         Print("Place short position now, price = ",getLatestClosePrice());
         //bool openShort = openSellPosition(0.01, 150, -100);
      }
      //upper = false;
  }
  
  if(iRSIReady_long){
      if(iOsMABuffer[1]>iOsMABuffer[0]){
         iRSIReady_long = false;
         SendNotification("Place long position now, price = "+getLatestClosePrice());
         Print("Place long position now, price = ",getLatestClosePrice());
         bool openLong = openPosition(0.01, -100, 150);
      }
      //lower = false;
  }
  
   int positionTotal = PositionsTotal();
   ArrayResize(tickets,positionTotal);
   for(int x=0; x<positionTotal; x++){
      type=EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
      ticket=PositionGetTicket(x);// ticket of the position
      if(type == "ORDER_TYPE_BUY"){
         if(iOsMABuffer[1]<iOsMABuffer[0]){
            bool closePosition = trade.PositionClose(ticket,1);
         }
      }else if(type == "ORDER_TYPE_SELL"){
         if(iOsMABuffer[1]>iOsMABuffer[0]){
            bool closePosition = trade.PositionClose(ticket,1);
         }
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

//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(string symbol,int fill_type) 
  { 
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=(int)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE); 
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type); 
  }
  
bool openPosition(double volume, double slDigits, double tpDigits){
         ZeroMemory(request);
         double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         sl=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK)+slDigits*point,_Digits);
         tp=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK)+tpDigits*point,_Digits);
         request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
         request.symbol   =Symbol();                              // symbol
         request.volume   =volume;                                   // volume of 0.1 lot
         request.type     =type;                        // order type
         request.price    =NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits); // price for opening
         request.deviation=10;
         request.sl = sl;
         request.tp = tp;                                     // allowed deviation from the price
         request.magic    =EA_Magic;   
         request.type_filling = ORDER_FILLING_IOC;  
         OrderSend(request,result);
         return true;
}

bool openSellPosition(double volume, double slDigits, double tpDigits){
         ZeroMemory(request);
         double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         sl=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK)+slDigits*point,_Digits);
         tp=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK)+tpDigits*point,_Digits);
         request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
         request.symbol   =Symbol();                              // symbol
         request.volume   =volume;                                   // volume of 0.1 lot
         request.type     =ORDER_TYPE_SELL;                        // order type
         request.price    =NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits); // price for opening
         request.deviation=10;
         request.sl = sl;
         request.tp = tp;                                     // allowed deviation from the price
         request.magic    =EA_Magic;   
         request.type_filling = ORDER_FILLING_IOC;  
         OrderSend(request,result);
         return true;
}