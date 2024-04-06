//+------------------------------------------------------------------+
//|                                      THE MATRIX FIB ZONES EA.mq5 |
//|                                              underground traders |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "underground traders, THE MATRIX FIB ZONES EA"
#property link      "https://www.mql5.com"
#property version   "1.0"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//Removed checking candle  and entering 2 turning candle
//
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
  

input double                     target_percentage = 10000000;       //Target Percentage
input double                     StopLoss      = 30000;       //Stop Loss in Points

input string                     NoteSettings      = "<=== OTHER SETTINGS ===>";//<==========================>
input double                     LotSize = 1 ;                 //Lot Size (0 if Dynamic)
input double                     LotMultiplier = 10000;        //Lot Multiplier
input ENUM_MART                  LotIncrease   = NO;          //Martingale
input int                        mart_max      = 2;            //Martingale Steps
input int                        tradespersignal = 2 ;
input ENUM_TIMEFRAMES            tradingTf = PERIOD_M1 ;
input enType                     trade_Type = Both_Type ;
input bool                       useEnvelopeForSLandTP = true ;
input double                     enveLopCloseBuy = 80 ;
input double                     envelopCloseSell = 20 ;
input bool                       useTrailing = false ;
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
input ulong                      emagic = 001234 ;
input ENUM_MART manualTrade = YES;//Manual Trading

input string                     Tcoment = "THE MATRIX FIB ZONES  EA " ;

string name0P_00 = "Fibo0P_00";
string name0P_1 = "Fibo0P_1";
string name1P_02 = "Fibo1P_02";
string name1P_04 = "Fibo1P_04";
string name2P_105 = "Fibo2P_105";
string name2P_145 = "Fibo2P_145";
string name3P_23 = "Fibo3P_23";
string name3P_27 = "Fibo3P_27";
string name4P_355 = "Fibo4P_355";
string name4P_395 = "Fibo4P_395";
string name5P_48 = "Fibo5P_48";
string name5P_52 = "Fibo5P_52";
string name6P_605 = "Fibo6P_605";
string name6P_645 = "Fibo6P_645";
string name7P_73 = "Fibo7P_73";
string name7P_77 = "Fibo7P_77";
string name8P_855 = "Fibo8P_855";
string name8P_895 = "Fibo8P_895";
string name9P_98 = "Fibo9P_98";
string name9P_1_02 = "Fibo9P_1_02";

double                           rsi_[],ma_1[],ma_2[],enve[] ;
int                              h_rsi,h_ma_20,h_envelp,h_ma_2 ;
double                           lotSize;
int lot_count=0;
int previous_loss_count = 0;
double LAST_TRADE_PROFIT=0;
double target_balance;
MqlRates bar[];

string BtnCall = "callButton";
string BtnPut = "putButton";
datetime open_binary;
int socket;   // Socket handle
input string Address = "192.168.0.112";
input int Port = 6000;
bool ExtTLS = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArraySetAsSeries(bar,true);
   
   //For trading buttons
   if(manualTrade==YES)
     {
      createButton(BtnCall,"CALL",20,200,clrAntiqueWhite,clrGreen);
      createButton(BtnPut,"PUT",20,300,clrAntiqueWhite,clrRed);
      ChartRedraw();
     }

   trade.SetExpertMagicNumber(emagic) ;

   ObjectCreate(0, name1P_02, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name1P_04, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name2P_105, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name2P_145, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name3P_23, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name3P_27, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name4P_355, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name4P_395, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name5P_48, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name5P_52, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name6P_605, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name6P_645, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name7P_73, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name7P_77, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name8P_855, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name8P_895, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name9P_98, OBJ_HLINE, 0, 0, 0);
   ObjectCreate(0, name9P_1_02, OBJ_HLINE, 0, 0, 0);

   ObjectSetInteger(0, name1P_02, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name1P_04, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name2P_105, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name2P_145, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name3P_23, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name3P_27, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name4P_355, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name4P_395, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name5P_48, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name5P_52, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name6P_605, OBJPROP_COLOR,clrBlack );
   ObjectSetInteger(0, name6P_645, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name7P_73, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name7P_77, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name8P_855, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name8P_895, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name9P_98, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name9P_1_02, OBJPROP_COLOR, clrBlack);


   ArraySetAsSeries(rsi_,true) ;
   ArraySetAsSeries(ma_1,true) ;
   ArraySetAsSeries(ma_2,true) ;
   ArraySetAsSeries(enve,true) ;



   h_rsi = iRSI(NULL,tradingTf,rsi_period,PRICE_WEIGHTED) ;
   h_ma_20 = iMA(NULL,tradingTf,ma_1period,ma_1shift,MODE_SMA,h_rsi) ;
   h_ma_2 = iMA(NULL,tradingTf,ma_2period,ma_2shift,MODE_SMA,h_rsi) ;
   h_envelp = iEnvelopes(NULL,tradingTf,envelope_priod,0,MODE_SMA,h_rsi,envelope_deviation) ;


//Get current account balance
   double start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

//Calculate the target balance and save
   target_balance = start_balance * (1+target_percentage/100);
   GlobalVariableSet("Target_Balance", target_balance);
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
  
    // close trade after 3 minutes
    if (PositionsTotal() > 0)
    {
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong ticket = PositionGetTicket(i);
            PositionSelectByTicket(ticket);

            // Check the opening time of the trade
            datetime openTime = PositionGetInteger(POSITION_TIME);
            datetime currentTime = TimeCurrent();
            int minutesPassed = (currentTime - openTime) / 60;

            if (minutesPassed >= 3)
            {
                // Close the trade
                trade.PositionClose(ticket, -1);
            }
        }
    }

   CopyRates(_Symbol,PERIOD_CURRENT,0,10,bar);
   if(LotSize<=0)
     {
      lotSize = DynamicLot();
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
        }
     }


//******************************************Function to calculate lot size********************************//

   CopyBuffer(h_rsi,0,0,4,rsi_) ;
   CopyBuffer(h_ma_20,0,0,4,ma_1) ;
   CopyBuffer(h_ma_2,0,0,4,ma_2) ;
   CopyBuffer(h_envelp,0,0,4,enve) ;

   double ask = SymbolInfoDouble(NULL,SYMBOL_ASK) ;
   double bid = SymbolInfoDouble(NULL,SYMBOL_BID) ;

   double p_1 = ChartGetDouble(0, CHART_PRICE_MAX);
   double p_0 = ChartGetDouble(0, CHART_PRICE_MIN);
   double l_c = iClose(NULL, PERIOD_CURRENT, 2); // close price of the 3rd candle

   double zone1P_02 = NormalizeDouble(p_0 + 0.02 * (p_1 - p_0), _Digits);
   double zone1P_04 = NormalizeDouble(p_0 + 0.04 * (p_1 - p_0), _Digits);
   double zone2P_105 = NormalizeDouble(p_0 + 0.105 * (p_1 - p_0), _Digits);
   double zone2P_145 = NormalizeDouble(p_0 + 0.145 * (p_1 - p_0), _Digits);
   double zone3P_23 = NormalizeDouble(p_0 + 0.23 * (p_1 - p_0), _Digits);
   double zone3P_27 = NormalizeDouble(p_0 + 0.27 * (p_1 - p_0), _Digits);
   double zone4P_355 = NormalizeDouble(p_0 + 0.355 * (p_1 - p_0), _Digits);
   double zone4P_395 = NormalizeDouble(p_0 + 0.395 * (p_1 - p_0), _Digits);
   double zone5P_48 = NormalizeDouble(p_0 + 0.48 * (p_1 - p_0), _Digits);
   double zone5P_52 = NormalizeDouble(p_0 + 0.52 * (p_1 - p_0), _Digits);
   double zone6P_605 = NormalizeDouble(p_0 + 0.605 * (p_1 - p_0), _Digits);
   double zone6P_645 = NormalizeDouble(p_0 + 0.645 * (p_1 - p_0), _Digits);
   double zone7P_73 = NormalizeDouble(p_0 + 0.73 * (p_1 - p_0), _Digits);
   double zone7P_77 = NormalizeDouble(p_0 + 0.77 * (p_1 - p_0), _Digits);
   double zone8P_855 = NormalizeDouble(p_0 + 0.855 * (p_1 - p_0), _Digits);
   double zone8P_895 = NormalizeDouble(p_0 + 0.895 * (p_1 - p_0), _Digits);
   double zone9P_98 = NormalizeDouble(p_0 + 0.98 * (p_1 - p_0), _Digits);
   double zone9P_1_02 = NormalizeDouble(p_0 + 1.02 * (p_1 - p_0), _Digits);

   ObjectSetDouble(0, name0P_00,OBJPROP_PRICE,p_0) ;
   ObjectSetDouble(0, name0P_1,OBJPROP_PRICE,p_1) ;
   ObjectSetDouble(0, name1P_02, OBJPROP_PRICE, zone1P_02);
   ObjectSetDouble(0, name1P_04, OBJPROP_PRICE, zone1P_04);
   ObjectSetDouble(0, name2P_105, OBJPROP_PRICE, zone2P_105);
   ObjectSetDouble(0, name2P_145, OBJPROP_PRICE, zone2P_145);
   ObjectSetDouble(0, name3P_23, OBJPROP_PRICE, zone3P_23);
   ObjectSetDouble(0, name3P_27, OBJPROP_PRICE, zone3P_27);
   ObjectSetDouble(0, name4P_355, OBJPROP_PRICE, zone4P_355);
   ObjectSetDouble(0, name4P_395, OBJPROP_PRICE, zone4P_395);
   ObjectSetDouble(0, name5P_48, OBJPROP_PRICE, zone5P_48);
   ObjectSetDouble(0, name5P_52, OBJPROP_PRICE, zone5P_52);
   ObjectSetDouble(0, name6P_605, OBJPROP_PRICE, zone6P_605);
   ObjectSetDouble(0, name6P_645, OBJPROP_PRICE, zone6P_645);
   ObjectSetDouble(0, name7P_73, OBJPROP_PRICE, zone7P_73);
   ObjectSetDouble(0, name7P_77, OBJPROP_PRICE, zone7P_77);
   ObjectSetDouble(0, name8P_855, OBJPROP_PRICE, zone8P_855);
   ObjectSetDouble(0, name8P_895, OBJPROP_PRICE, zone8P_895);
   ObjectSetDouble(0, name9P_98, OBJPROP_PRICE, zone9P_98);
   ObjectSetDouble(0, name9P_1_02, OBJPROP_PRICE, zone9P_1_02);

   double c1P_02 = NormalizeDouble(ObjectGetDouble(0, name1P_02, OBJPROP_PRICE), _Digits);
   double c1P_04 = NormalizeDouble(ObjectGetDouble(0, name1P_04, OBJPROP_PRICE), _Digits);
   double c2P_105 = NormalizeDouble(ObjectGetDouble(0, name2P_105, OBJPROP_PRICE), _Digits);
   double c2P_145 = NormalizeDouble(ObjectGetDouble(0, name2P_145, OBJPROP_PRICE), _Digits);
   double c3P_23 = NormalizeDouble(ObjectGetDouble(0, name3P_23, OBJPROP_PRICE), _Digits);
   double c3P_27 = NormalizeDouble(ObjectGetDouble(0, name3P_27, OBJPROP_PRICE), _Digits);
   double c4P_355 = NormalizeDouble(ObjectGetDouble(0, name4P_355, OBJPROP_PRICE), _Digits);
   double c4P_395 = NormalizeDouble(ObjectGetDouble(0, name4P_395, OBJPROP_PRICE), _Digits);
   double c5P_48 = NormalizeDouble(ObjectGetDouble(0, name5P_48, OBJPROP_PRICE), _Digits);
   double c5P_52 = NormalizeDouble(ObjectGetDouble(0, name5P_52, OBJPROP_PRICE), _Digits);
   double c6P_605 = NormalizeDouble(ObjectGetDouble(0, name6P_605, OBJPROP_PRICE), _Digits);
   double c6P_645 = NormalizeDouble(ObjectGetDouble(0, name6P_645, OBJPROP_PRICE), _Digits);
   double c7P_73 = NormalizeDouble(ObjectGetDouble(0, name7P_73, OBJPROP_PRICE), _Digits);
   double c7P_77 = NormalizeDouble(ObjectGetDouble(0, name7P_77, OBJPROP_PRICE), _Digits);
   double c8P_855 = NormalizeDouble(ObjectGetDouble(0, name8P_855, OBJPROP_PRICE), _Digits);
   double c8P_895 = NormalizeDouble(ObjectGetDouble(0, name8P_895, OBJPROP_PRICE), _Digits);
   double c9P_98 = NormalizeDouble(ObjectGetDouble(0, name9P_98, OBJPROP_PRICE), _Digits);
   double c9P_1_02 = NormalizeDouble(ObjectGetDouble(0, name9P_1_02, OBJPROP_PRICE), _Digits);
//Check if global target is not reached yet.
   if(AccountInfoDouble(ACCOUNT_BALANCE) < GlobalVariableGet("Target_Balance"))

     {

      if(
         (l_c < c1P_02 && l_c > c1P_04) ||
         (l_c < c2P_105 && l_c > c2P_145) ||
         (l_c < c3P_23 && l_c > c3P_27)||
         (l_c < c4P_355 && l_c > c4P_395) ||
         (l_c < c5P_48 && l_c > c5P_52) ||
         (l_c < c6P_605 && l_c > c6P_645) ||
         (l_c < c7P_73 && l_c < c7P_77) ||
         (l_c < c8P_855 && l_c > c8P_895) ||
         (l_c < c9P_98 && l_c > c9P_1_02)
      )
        {
         //Print("We are inside the trade area");
         if(
            ma_1[0]>ma_1sell_level &&
            ma_2[1]>ma_2sell_level &&
            enve[1]>envelope_sell_level&&
            SymbolPositionsTotal()<tradespersignal &&
            (trade_Type==Both_Type||trade_Type==sell)&&
            ma_2[1]<enve[1]&&
            ma_2[2]>enve[2] &&
            ma_2[0]<enve[0]&&
            previous_loss_count < 4 )
           {
            Print("First Level: Sell signal found. Waiting for confirmation");
            sendSignal("sell");
Alert("Sell Signal for "+_Symbol);
            trade.Sell(
               lotSize,
               NULL,
               bid, //Sell Price
               bid+StopLoss*_Point, //Stop Loss
               0,
               Tcoment
            ) ;

           }
          
          
            if(
         (l_c < c1P_02 && l_c > c1P_04) ||
         (l_c < c2P_105 && l_c > c2P_145) ||
         (l_c < c3P_23 && l_c > c3P_27)||
         (l_c < c4P_355 && l_c > c4P_395) ||
         (l_c < c5P_48 && l_c > c5P_52) ||
         (l_c < c6P_605 && l_c > c6P_645) ||
         (l_c < c7P_73 && l_c < c7P_77) ||
         (l_c < c8P_855 && l_c > c8P_895) ||
         (l_c < c9P_98 && l_c > c9P_1_02)
      )
         if(
            ma_1[0]<ma_1buy_level &&
            ma_2[1]<ma_2buy_level&&
            enve[1]<envelope_buy_level &&
            SymbolPositionsTotal()<tradespersignal&&
            (trade_Type==Both_Type||trade_Type==buy)&&
            ma_2[0]>enve[0]&&
            ma_2[1]>enve[1]&&
            ma_2[2]<enve[2] &&
            previous_loss_count < 4)
           {
            Print("First Level: Buy signal found. Waiting for confirmation");//
            Alert("Buy Signal for "+_Symbol);
            sendSignal("buy");
            trade.Buy(
               lotSize,
               NULL,
               ask, //Buy Price
               ask-StopLoss*_Point, //Stop Loss
               0,
               Tcoment
            ) ;

           }
        }
     }
   else
     {
      string oName="Target_Reached";
      datetime tim=iTime(_Symbol,PERIOD_CURRENT,1);
      double price=iHigh(_Symbol,PERIOD_CURRENT,1);
      ObjectCreate(0,oName,OBJ_TEXT,0,tim,price);
      ObjectSetString(0,oName,OBJPROP_TEXT,"Target balance has been reached");
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//Print("Number of open position =  ",NumberOfOpenPositions," for ", Symbol());
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


//------------------------------------------------------------------+
//+------------------------------------------------------------------+
void  OnChartEvent(
   const int       id,       // event ID
   const long&     lparam,   // long type event parameter
   const double&   dparam,   // double type event parameter
   const string&   sparam    // string type event parameter
)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == BtnCall)
        {
         sendSignal("buy");
         ObjectSetInteger(0,BtnCall,OBJPROP_STATE,false);
        }
      if(sparam == BtnPut)
        {
         sendSignal("sell");
         ObjectSetInteger(0,BtnPut,OBJPROP_STATE,false);
        }
     }
  }
//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket,string request)
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0)
      return(false);
//--- if secure TLS connection is used via the port 443
   if(ExtTLS)
      return(SocketTlsSend(socket,req,len)==len);
//--- if standard TCP connection is used
   return(SocketSend(socket,req,len)==len);
  }
//+------------------------------------------------------------------+
//| Read server response                                             |
//+------------------------------------------------------------------+
bool HTTPRecv(int socket,uint timeout)
  {
   char   rsp[];
   string result;
   uint   timeout_check=GetTickCount()+timeout;
//--- read data from sockets till they are still present but not longer than timeout
   do
     {
      uint len=SocketIsReadable(socket);
      if(len)
        {
         int rsp_len;
         //--- various reading commands depending on whether the connection is secure or not
         if(ExtTLS)
            rsp_len=SocketTlsRead(socket,rsp,len);
         else
            rsp_len=SocketRead(socket,rsp,len,timeout);
         //--- analyze the response
         if(rsp_len>0)
           {
            result+=CharArrayToString(rsp,0,rsp_len);
            //--- print only the response header
            int header_end=StringFind(result,"\r\n\r\n");
            if(header_end>0)
              {
               Print("HTTP answer header received:");
               Print(StringSubstr(result,0,header_end));
               return(true);
              }
           }
        }
     }
   while(GetTickCount()<timeout_check && !IsStopped());
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendSignal(string trade_option)
  {
//if(trade_option=='buy'){

//}
   datetime TimeNow = TimeCurrent();
   if(open_binary < TimeNow)
     {
      open_binary = TimeNow+300;
      socket=SocketCreate();
      //--- check the handle
      if(socket!=INVALID_HANDLE)
        {
         //--- connect if all is well
         if(SocketConnect(socket,Address,Port,1000))
           {
            Print("Established connection to ",Address,":",Port);

            string   subject,issuer,serial,thumbprint;
            datetime expiration;
            //--- if connection is secured by the certificate, display its data
            if(SocketTlsCertificate(socket,subject,issuer,serial,thumbprint,expiration))
              {
               Print("TLS certificate:");
               Print("   Owner:  ",subject);
               Print("   Issuer:  ",issuer);
               Print("   Number:     ",serial);
               Print("   Print: ",thumbprint);
               Print("   Expiration: ",expiration);
               ExtTLS=true;
              }
            //--- send GET request to the server
            string msg;
            StringConcatenate(msg, "{\"symbol\":\"",_Symbol,"\",","\"trade_option\":\"",trade_option,"\",\"msg_type\":\"signal\"}");
            //string signal =  "{\"symbol\":\"",_Symbol,"\",","\"trade_option\":\"",trade_option,"\",\"msg_type\":\"signal\"}");
            if(HTTPSend(socket,msg))
              {
               Print("GET request sent");
               //--- read the response
               if(!HTTPRecv(socket,1000))
                  Print("Failed to get a response, error ",GetLastError());
              }
            else
               Print("Failed to send GET request, error ",GetLastError());
           }
         else
           {
            Print("Connection to ",Address,":",Port," failed, error ",GetLastError());
           }
         //--- close a socket after using
         SocketClose(socket);
        }
      else
         Print("Failed to create a socket, error ",GetLastError());
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createButton(string objName,string text, int x, int y, color clrTxt, color clrBg)
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(0,objName,OBJ_BUTTON,0,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
     }
//--- set button coordinates
   ObjectSetInteger(0,objName,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,objName,OBJPROP_YDISTANCE,y);
//--- set button size
   ObjectSetInteger(0,objName,OBJPROP_XSIZE,150);
   ObjectSetInteger(0,objName,OBJPROP_YSIZE,50);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(0,objName,OBJPROP_CORNER,CORNER_LEFT_UPPER);
//--- set the text
   ObjectSetString(0,objName,OBJPROP_TEXT,text);

   ObjectSetInteger(0,objName,OBJPROP_FONTSIZE,12);
//--- set text color
   ObjectSetInteger(0,objName,OBJPROP_COLOR,clrTxt);
//--- set background color
   ObjectSetInteger(0,objName,OBJPROP_BGCOLOR,clrBg);
//--- set border color
   ObjectSetInteger(0,objName,OBJPROP_BORDER_COLOR,clrAliceBlue);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(0,objName,OBJPROP_BACK,false);
//--- set button state
   ObjectSetInteger(0,objName,OBJPROP_STATE,false);
//--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(0,objName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,objName,OBJPROP_SELECTED,false);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(0,objName,OBJPROP_HIDDEN,false);
//--- successful execution
   return(true);

  }