//+------------------------------------------------------------------+
//|                                             SLEDGE HAMMER EA.mq5 |
//|                                              underground traders |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "underground traders"
#property link      "https://www.mql5.com"
#property version   "3.0"

//Updates:
//Use fib for entry yes or no
//Stop trade if 2 stop loss and wait for moving average to go back again

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include  <trade\Trade.mqh>

CTrade trade ;

enum enType
  {
   buy,
   sell,
   Both_Type,
  };
enum ENUM_MART
  {
   YES,  //Yes
   NO, //No
  };

input string                     FiboSettings   = "<=== FIBO OPTION SETTINGS ===>";//<==========================>
input bool                       useFIBOforEntry = false ; //Use Fibo for Trade Entry
input bool                       useFIBOforTPandSL = false ;
input double                     StopLoss      = 3000;       //Stop Loss in Points

input string                     NoteSettings      = "<=== OTHER SETTINGS ===>";//<==========================>
input double                     LotSize = 0 ;                 //Lot Size (0 if Dynamic)
input double                     LotMultiplier = 10000;        //Lot Multiplier
input ENUM_MART                  LotIncrease   = YES;          //Martingale
input int                        mart_max      = 2;            //Martingale Steps
input int                        tradespersignal = 1 ;
input ENUM_TIMEFRAMES            tradingTf = PERIOD_M5 ;
input enType                     trade_Type = Both_Type ;
input bool                       useEnvelopeForSLandTP = true ;
input double                     enveLopCloseBuy = 80 ;
input double                     envelopCloseSell = 20 ;
input bool                       useTrailing = true ;
input int                        Trailing_start_pips = 20 ;
input int                        Trailig_Distance = 10 ;
input int                        rsi_period = 5  ;
input int                        ma_1period = 20 ;
input int                        ma_1shift = -1 ;
input int                        ma_1buy_level = 40 ;
input int                        ma_1sell_level = 60 ;
input int                        ma_2period = 2 ;
input int                        ma_2shift = -1 ;
input int                        ma_2buy_level = 20 ;
input int                        ma_2sell_level = 80 ;
input int                        envelope_priod = 3 ;
input double                     envelope_deviation = 0.2 ;
input double                     envelope_buy_level = 20 ;
input double                     envelope_sell_level = 80 ;
input ulong                      emagic = 616161 ;
input string                     Tcoment = "B&C EA " ;
string name_0                    = "Fibo_0" ;
string name_315                  = "Fibo_315" ;
string name_125                  = "Fibo_125" ;
string name_25                   = "Fibo_25" ;
string name_5                    = "Fibo_5" ;
string name_75                   = "Fibo_75" ;
string name_565                  = "Fibo_565" ;
string name_1                    = "Fibo_1" ;
string name_44                   = "Fibo_44" ;
string name_875                  = "Fibo_875" ;
string name_625                  = "Fibo_625" ;
string name_375                  = "Fibo_375" ;
string name_9375                 = "Fibo_9375" ;
string name_19                   = "Fibo_19" ;
string name_065                  = "Fibo_065" ;
string name_815                  = "Fibo_815" ;
string name_69                   = "Fibo_69" ;

double                           rsi_[],ma_1[],ma_2[],enve[] ;
int                              h_rsi,h_ma_20,h_envelp,h_ma_2 ;
double                           lotSize;
int lot_count=0;
int previous_loss_count = 0;
double LAST_TRADE_PROFIT=0;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(emagic) ;

   ObjectCreate(0,name_0,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_315,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_125,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_25,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_5,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_75,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_565,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_1,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_44,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_875,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_625,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_375,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_9375,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_19,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_065,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_815,OBJ_HLINE,0,0,0) ;
   ObjectCreate(0,name_69,OBJ_HLINE,0,0,0) ;

   ObjectSetInteger(0,name_0,OBJPROP_COLOR,clrRed) ;
   ObjectSetInteger(0,name_315,OBJPROP_COLOR,clrAqua) ;
   ObjectSetInteger(0,name_125,OBJPROP_COLOR,clrGreenYellow) ;
   ObjectSetInteger(0,name_25,OBJPROP_COLOR,clrPink) ;
   ObjectSetInteger(0,name_5,OBJPROP_COLOR,clrBisque) ;
   ObjectSetInteger(0,name_75,OBJPROP_COLOR,clrRoyalBlue) ;
   ObjectSetInteger(0,name_565,OBJPROP_COLOR,clrViolet) ;
   ObjectSetInteger(0,name_1,OBJPROP_COLOR,clrBurlyWood) ;
   ObjectSetInteger(0,name_44,OBJPROP_COLOR,clrDarkOrchid) ;
   ObjectSetInteger(0,name_875,OBJPROP_COLOR,clrDarkCyan);
   ObjectSetInteger(0,name_625,OBJPROP_COLOR,clrBlanchedAlmond) ;
   ObjectSetInteger(0,name_375,OBJPROP_COLOR,clrChocolate) ;
   ObjectSetInteger(0,name_9375,OBJPROP_COLOR,clrFuchsia) ;
   ObjectSetInteger(0,name_19,OBJPROP_COLOR,clrAzure) ;
   ObjectSetInteger(0,name_065,OBJPROP_COLOR,clrCornsilk);
   ObjectSetInteger(0,name_815,OBJPROP_COLOR,clrHotPink) ;
   ObjectSetInteger(0,name_69,OBJPROP_COLOR,clrGold) ;
   ObjectSetInteger(0,name_315,OBJPROP_COLOR,clrPlum) ;

   ArraySetAsSeries(rsi_,true) ;
   ArraySetAsSeries(ma_1,true) ;
   ArraySetAsSeries(ma_2,true) ;
   ArraySetAsSeries(enve,true) ;



   h_rsi = iRSI(NULL,tradingTf,rsi_period,PRICE_WEIGHTED) ;
   h_ma_20 = iMA(NULL,tradingTf,ma_1period,ma_1shift,MODE_SMA,h_rsi) ;
   h_ma_2 = iMA(NULL,tradingTf,ma_2period,ma_2shift,MODE_SMA,h_rsi) ;
   h_envelp = iEnvelopes(NULL,tradingTf,envelope_priod,0,MODE_SMA,h_rsi,envelope_deviation) ;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   ObjectsDeleteAll(0,-1,-1) ;

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Print("Previous Loss Count for "+_Symbol+" = "+IntegerToString(previous_loss_count));
   if(LotSize<=0)
     {
      lotSize = DynamicLot();
      //Print("Lot size used is ",Lots);
     }
   else
     {
      lotSize = LotSize;
     }
   if(LotIncrease==YES)
     {
      if(Martingale() > 0)
        {
         lotSize = Martingale();
         Print("Lot Increase, New lot is ", Martingale());
        }
     }


//******************************************Function to calculate lot size********************************//

   CopyBuffer(h_rsi,0,0,4,rsi_) ;
   CopyBuffer(h_ma_20,0,0,4,ma_1) ;
   CopyBuffer(h_ma_2,0,0,4,ma_2) ;
   CopyBuffer(h_envelp,0,0,4,enve) ;

   double ask = SymbolInfoDouble(NULL,SYMBOL_ASK) ;
   double bid = SymbolInfoDouble(NULL,SYMBOL_BID) ;

   double  p_1 = ChartGetDouble(0,CHART_PRICE_MAX) ;
   double p_0 = ChartGetDouble(0,CHART_PRICE_MIN) ;
   double l_c = iClose(NULL,PERIOD_CURRENT,2) ;

   double p_125 = NormalizeDouble(p_0+0.125*(p_1-p_0),_Digits) ;
   double p_25 = NormalizeDouble(p_0+0.25*(p_1-p_0),_Digits) ;
   double p_5 = NormalizeDouble(p_0+0.5*(p_1-p_0),_Digits) ;
   double p_75 = NormalizeDouble(p_0+0.75*(p_1-p_0),_Digits) ;
   double p_565 = NormalizeDouble(p_0+0.565*(p_1-p_0),_Digits) ;
   double p_44 = NormalizeDouble(p_0+0.44*(p_1-p_0),_Digits) ;
   double p_875= NormalizeDouble(p_0+0.875*(p_1-p_0),_Digits) ;
   double p_625 = NormalizeDouble(p_0+0.625*(p_1-p_0),_Digits) ;
   double p_375 = NormalizeDouble(p_0+0.375*(p_1-p_0),_Digits) ;
   double p_9375 = NormalizeDouble(p_0+0.9375*(p_1-p_0),_Digits) ;
   double p_19 = NormalizeDouble(p_0+0.19*(p_1-p_0),_Digits) ;
   double p_065 = NormalizeDouble(p_0+0.065*(p_1-p_0),_Digits) ;
   double p_815 = NormalizeDouble(p_0+0.815*(p_1-p_0),_Digits) ;
   double p_69 = NormalizeDouble(p_0+0.69*(p_1-p_0),_Digits) ;
   double p_315 = NormalizeDouble(p_0+0.315*(p_1-p_0),_Digits) ;



   ObjectSetDouble(0,name_0,OBJPROP_PRICE,p_0) ;
   ObjectSetDouble(0,name_1,OBJPROP_PRICE,p_1) ;
   ObjectSetDouble(0,name_125,OBJPROP_PRICE,p_125) ;
   ObjectSetDouble(0,name_25,OBJPROP_PRICE,p_25) ;
   ObjectSetDouble(0,name_5,OBJPROP_PRICE,p_5) ;
   ObjectSetDouble(0,name_75,OBJPROP_PRICE,p_75) ;
   ObjectSetDouble(0,name_565,OBJPROP_PRICE,p_565) ;
   ObjectSetDouble(0,name_44,OBJPROP_PRICE,p_44) ;
   ObjectSetDouble(0,name_875,OBJPROP_PRICE,p_875) ;
   ObjectSetDouble(0,name_625,OBJPROP_PRICE,p_625) ;
   ObjectSetDouble(0,name_375,OBJPROP_PRICE,p_375) ;
   ObjectSetDouble(0,name_9375,OBJPROP_PRICE,p_9375) ;
   ObjectSetDouble(0,name_19,OBJPROP_PRICE,p_19) ;
   ObjectSetDouble(0,name_065,OBJPROP_PRICE,p_065) ;
   ObjectSetDouble(0,name_815,OBJPROP_PRICE,p_815) ;
   ObjectSetDouble(0,name_69,OBJPROP_PRICE,p_69) ;
   ObjectSetDouble(0,name_315,OBJPROP_PRICE,p_315) ;

  
   double c_125 = NormalizeDouble(ObjectGetDouble(0,name_125,OBJPROP_PRICE),_Digits) ;
   double c_25 = NormalizeDouble(ObjectGetDouble(0,name_25,OBJPROP_PRICE),_Digits) ;
   double c_5 = NormalizeDouble(ObjectGetDouble(0,name_5,OBJPROP_PRICE),_Digits) ;
   double c_75 = NormalizeDouble(ObjectGetDouble(0,name_75,OBJPROP_PRICE),_Digits) ;
   double c_565 = NormalizeDouble(ObjectGetDouble(0,name_565,OBJPROP_PRICE),_Digits) ;
   double c_44 = NormalizeDouble(ObjectGetDouble(0,name_44,OBJPROP_PRICE),_Digits) ;
   double c_875= NormalizeDouble(ObjectGetDouble(0,name_875,OBJPROP_PRICE),_Digits) ;
   double c_625 = NormalizeDouble(ObjectGetDouble(0,name_625,OBJPROP_PRICE),_Digits) ;
   double c_375 = NormalizeDouble(ObjectGetDouble(0,name_375,OBJPROP_PRICE),_Digits) ;
   double c_9375 = NormalizeDouble(ObjectGetDouble(0,name_9375,OBJPROP_PRICE),_Digits) ;
   double c_19 = NormalizeDouble(ObjectGetDouble(0,name_19,OBJPROP_PRICE),_Digits) ;
   double c_065 = NormalizeDouble(ObjectGetDouble(0,name_065,OBJPROP_PRICE),_Digits) ;
   double c_815 = NormalizeDouble(ObjectGetDouble(0,name_815,OBJPROP_PRICE),_Digits) ;
   double c_69 = NormalizeDouble(ObjectGetDouble(0,name_69,OBJPROP_PRICE),_Digits) ;
   double c_315 = NormalizeDouble(ObjectGetDouble(0,name_315,OBJPROP_PRICE),_Digits) ;
   if(ma_1[0]<ma_1buy_level&&ma_2[0]<ma_2buy_level&&enve[0]<envelope_buy_level && SymbolPositionsTotal()<tradespersignal&&(trade_Type==Both_Type||trade_Type==buy)&&ma_2[0]>enve[0]&&ma_2[2]<enve[2] && previous_loss_count < 2)
     {
      if(useFIBOforEntry == false)
        {
         //If previous_loss-count is less than 2 then enter
         trade.Buy(
            lotSize,
            NULL,
            ask, //Buy Price
            ask-StopLoss*_Point, //Stop Loss
            0,
            Tcoment
         ) ;
        }
      else
        {
         if(bid<=c_065&&l_c>=c_065&&c_125>bid)
           {
            //Check if use fibo for stoploss and tp is selected
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,p_0,c_125,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,p_0,0,Tcoment) ;
                 }
           }

         if(bid<=c_125 && l_c>=c_125&&c_19>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_065,c_19,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_065,0,Tcoment) ;
                 }


         if(bid<=c_19 && l_c>=c_19&&c_25>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_125,c_25,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_125,0,Tcoment) ;
                 }


         if(bid<=c_25&&l_c>=c_25&&c_315>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_19,c_315,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_19,0,Tcoment) ;
                 }

         if(bid<=c_315 && l_c>=c_315&&c_375>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_25,c_375,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_25,0,Tcoment) ;
                 }

         if(bid<=c_375 && l_c>=c_375&&c_44>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_315,c_44,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_315,0,Tcoment) ;
                 }

         if(bid<=c_44&&l_c>=c_44&&c_5>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_375,c_5,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_375,0,Tcoment) ;
                 }

         if(bid<=c_5 && l_c>=c_5&&c_565>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_44,c_565,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_44,0,Tcoment) ;
                 }

         if(bid<=c_565 && l_c>=c_565&&c_625>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_5,c_625,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_5,0,Tcoment) ;
                 }

         if(bid<=c_625&&l_c>=c_625&&c_69>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_565,c_69,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_565,0,Tcoment) ;
                 }

         if(bid<=c_69 && l_c>=c_69&&c_75>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_625,c_75,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_625,0,Tcoment) ;
                 }

         if(bid<=c_75 && l_c>=c_75&&c_815>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_69,c_815,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_69,0,Tcoment) ;
                 }

         if(bid<=c_815 && l_c>=c_815&&c_875>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_75,c_875,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_75,0,Tcoment) ;
                 }

         if(bid<=c_875 && l_c>=c_875&&c_9375>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_815,c_9375,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_815,0,Tcoment) ;
                 }

         if(bid<=c_9375 && l_c>=c_9375&&p_1>bid)
            if(useFIBOforTPandSL)
              {
               trade.Buy(lotSize,NULL,ask,c_875,p_1,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Buy(lotSize,NULL,ask,c_875,0,Tcoment) ;
                 }
        }
     }

   if(ma_1[0]>ma_1sell_level && ma_2[0]>ma_2sell_level&&enve[0]>envelope_sell_level&&SymbolPositionsTotal()<tradespersignal&&(trade_Type==Both_Type||trade_Type==sell)&&ma_2[0]<enve[0]&&ma_2[2]>enve[2] && previous_loss_count < 2)
      if(useFIBOforEntry == false)
        {
         trade.Sell(
            lotSize,
            NULL,
            bid, //Sell Price
            bid+StopLoss*_Point, //Stop Loss
            0,
            Tcoment
         ) ;
        }
      else
        {
         if(ask>=c_065&&l_c<=c_065&&p_0<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_125,p_0,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_125,0,Tcoment) ;
                 }

         if(ask>=c_125 && l_c<=c_125&&c_065<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_19,c_065,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_19,0,Tcoment) ;
                 }

         if(ask>=c_19 && l_c<=c_19&&c_125<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_25,c_125,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_25,0,Tcoment) ;
                 }

         if(ask>=c_25&&l_c<=c_25&&c_19<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_315,c_19,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_315,0,Tcoment) ;
                 }

         if(ask>=c_315 && l_c<=c_315&&c_25<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_375,c_25,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_375,0,Tcoment) ;
                 }


         if(ask>=c_375 && l_c<=c_375&&c_315<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_44,c_315,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_44,0,Tcoment) ;
                 }


         if(ask>=c_44&&l_c<=c_44&&c_375<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_5,c_375,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_5,0,Tcoment) ;
                 }


         if(ask>=c_5 && l_c<=c_5&&c_44<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_565,c_44,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_565,0,Tcoment) ;
                 }

         if(ask>=c_565 && l_c<=c_565&&c_5<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_625,c_5,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_625,0,Tcoment) ;
                 }

         if(ask>=c_625&&l_c<=c_625&&c_565<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_69,c_565,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_69,0,Tcoment) ;
                 }

         if(ask>=c_69 && l_c<=c_69&&c_625<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_75,c_625,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_75,0,Tcoment) ;
                 }

         if(ask>=c_75 && l_c<=c_75&&c_69<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_815,c_69,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_815,0,Tcoment) ;
                 }

         if(ask>=c_815 && l_c<=c_815&&c_75<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_875,c_75,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_875,0,Tcoment) ;
                 }

         if(ask>=c_875 && l_c<=c_875&&c_815<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_9375,c_815,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_9375,0,Tcoment) ;
                 }

         if(ask>=c_9375 && l_c<= c_9375&&c_875<ask)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,p_1,c_875,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,p_1,0,Tcoment) ;
                 }

         if(ask>=c_065&&l_c<=c_065&&p_0<ask&&useFIBOforTPandSL)
            if(useFIBOforTPandSL)
              {
               trade.Sell(lotSize,NULL,bid,c_125,p_0,Tcoment) ;
              }
            else
               if(useEnvelopeForSLandTP)
                 {
                  trade.Sell(lotSize,NULL,bid,c_125,0,Tcoment) ;
                 }
        }

   if(useTrailing==true && PositionsTotal()>0)
     {
      double trail = Trailig_Distance*_Point ;
      double buyTrail = NormalizeDouble(ask-trail,_Digits) ;
      double sellTrail = NormalizeDouble(bid+trail,_Digits) ;
      for(int i = PositionsTotal()-1 ; i>=0 ; i--)
        {
         ulong ticket = PositionGetTicket(i) ;
         PositionSelectByTicket(ticket) ;
         long type = PositionGetInteger(POSITION_TYPE) ;
         ulong posmagic = PositionGetInteger(POSITION_MAGIC) ;
         double posOpen = PositionGetDouble(POSITION_PRICE_OPEN) ;
         double posSL = PositionGetDouble(POSITION_SL) ;

         if(type==POSITION_TYPE_BUY && ask-posOpen>trail && posmagic==emagic && buyTrail>posOpen && buyTrail>posSL&&ask-posOpen>=Trailing_start_pips*_Point)
           {
            // ResetLastError();
            trade.PositionModify(ticket,buyTrail,0) ;
            //int code = GetLastError();
            //string codestr = IntegerToString(code,5,' ') ;
            //Comment(codestr) ;
           }
         else
            if(type==POSITION_TYPE_SELL && posOpen-bid>trail && posmagic==emagic && sellTrail<posOpen  && sellTrail<posSL&&posOpen-bid>=Trailing_start_pips*_Point)
               trade.PositionModify(ticket,sellTrail,0) ;


        }

     }

// close trade on envelopes
   if(PositionsTotal()>0)
     {
      for(int i = PositionsTotal()-1 ; i>=0 ; i--)
        {
         ulong ticket = PositionGetTicket(i) ;
         PositionSelectByTicket(ticket) ;
         long type = PositionGetInteger(POSITION_TYPE) ;
         ulong posmagic = PositionGetInteger(POSITION_MAGIC) ;

         if(posmagic==emagic && type==POSITION_TYPE_BUY&&enve[0]>=enveLopCloseBuy)
            trade.PositionClose(ticket,-1) ;
         if(posmagic==emagic&&type==POSITION_TYPE_SELL&&enve[0]<=envelopCloseSell)
            trade.PositionClose(ticket,-1) ;

        }

     }
//Reset Previous_loss_Count if Moving Average 20 goes back to
   if((ma_1[1] > 50 &&  ma_1[0] < 50) || (ma_1[1] < 50 &&  ma_1[0] > 50))
      previous_loss_count = 0;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DynamicLot()
  {
//Account Equity
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);

//Account Balance
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);

//Calculate Position/Lot Size
   double DynamicLotSize = NormalizeDouble(Equity/LotMultiplier,2);

   return DynamicLotSize; //Return Lot Size to the main function
  }
//---
int SymbolPositionsTotal()
  {
   int NumberOfOpenPositions = 0;//local variable for number of positions
   for(int i=PositionsTotal()-1; i>=0; i--)//look at all positions
     {
      string CurrencyPair = PositionGetSymbol(i);//identify currency pair

      if(Symbol() == CurrencyPair)//If Symbol on Chart Equals Position Symbol
        {
         //increase number of counted open positions
         NumberOfOpenPositions = NumberOfOpenPositions + 1;
        }
     }
   Print("Number of open position =  ",NumberOfOpenPositions," for ", Symbol());
   return NumberOfOpenPositions; //Return number of open positions to the main function
  }
//******************************************Function to check last closed order time and profit**************//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Martingale()
  {
//get the history for gap time
   HistorySelect(0,TimeCurrent());
   uint        TotalNumberOfDeals      = HistoryDealsTotal();
   ulong       TicketNumber            = 0;
   long        DealEntry;
   double      OrderProfit             = 0;
   string      MySymbol                = "";
   string      PositionDirection       = "";
   string      LotAllowIncrease        = "";
   long        DealMagicNumber;
   double      ClosedLot               =0;
   double      NewLot                  =0;




//go through all the deals
   for(uint i=0; i < TotalNumberOfDeals; i++)
     {
      //we look for ticket number
      if((TicketNumber = HistoryDealGetTicket(i))>0)
        {
         //Get the order Profit
         OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);

         //Get the magic number for the deal
         DealMagicNumber = HistoryDealGetInteger(TicketNumber,DEAL_MAGIC);

         //Get the Symbol
         MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);

         //Closed Lotsize
         ClosedLot = HistoryDealGetDouble(TicketNumber,DEAL_VOLUME);

         //Get the entry type to check for close type
         DealEntry = HistoryDealGetInteger(TicketNumber, DEAL_ENTRY);

         //Check Magic Number
         //if(DealMagicNumber == Magic)

         //Check if currency pair match
         if(MySymbol==_Symbol)

            //if order was closed
            if(DealEntry == 1)

               //Check time if less than specified minutes
               if(OrderProfit<0 && lot_count <= mart_max)
                 {

                  NewLot = ClosedLot*2 ;
                  lot_count = lot_count + 1;

                 }
               else
                 {
                  NewLot = lotSize;
                  lot_count = 0;
                 }
        }
     }
   return NewLot;

  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade()
  {
   static int previous_open_positions = 0;
   int current_open_positions = PositionsTotal();
   string symbol;
   if(current_open_positions < previous_open_positions)             // a position just got closed:
     {
      previous_open_positions = current_open_positions;
      HistorySelect(TimeCurrent()-300, TimeCurrent()); // 5 minutes ago
      int All_Deals = HistoryDealsTotal();
      if(All_Deals < 1)
         Print("Some nasty shit error has occurred :s");
      // last deal (should be an DEAL_ENTRY_OUT type):
      ulong temp_Ticket = HistoryDealGetTicket(All_Deals-1);
      symbol=HistoryDealGetString(temp_Ticket,DEAL_SYMBOL);
      // here check some validity factors of the position-closing deal
      // (symbol, position ID, even MagicNumber if you care...)
      LAST_TRADE_PROFIT = HistoryDealGetDouble(temp_Ticket, DEAL_PROFIT);
      if(symbol == _Symbol && LAST_TRADE_PROFIT < 0)
        {
         //Add to previous_loss_count
         previous_loss_count = previous_loss_count + 1;
         Print("Last Trade Profit : ", DoubleToString(LAST_TRADE_PROFIT));
        }
     }
   else
      if(current_open_positions > previous_open_positions)       // a position just got opened:
         previous_open_positions = current_open_positions;
  }
//+------------------------------------------------------------------+
