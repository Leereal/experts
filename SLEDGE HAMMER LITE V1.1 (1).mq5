//+------------------------------------------------------------------+
//|                                        SLEDGE HAMMER LITE EA.mq5 |
//|                                              underground traders |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "underground traders"
#property link      "https://www.mql5.com"
#property version   "1.1"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//Target percentage added
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
input double                     target_percentage = 10;       //Target Percentage
input double                     StopLoss      = 3000;       //Stop Loss in Points

input string                     NoteSettings      = "<=== OTHER SETTINGS ===>";//<==========================>
input double                     LotSize = 0 ;                 //Lot Size (0 if Dynamic)
input double                     LotMultiplier = 10000;        //Lot Multiplier
input ENUM_MART                  LotIncrease   = NO;          //Martingale
input int                        mart_max      = 2;            //Martingale Steps
input int                        tradespersignal = 1 ;
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
input string                     Tcoment = "SL Lite EA " ;

double                           rsi_[],ma_1[],ma_2[],enve[] ;
int                              h_rsi,h_ma_20,h_envelp,h_ma_2 ;
double                           lotSize;
int lot_count=0;
int previous_loss_count = 0;
double LAST_TRADE_PROFIT=0;
double target_balance;
MqlRates bar[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
ArraySetAsSeries(bar,true);
   trade.SetExpertMagicNumber(emagic) ;


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

//Check if global target is not reached yet.
   if(AccountInfoDouble(ACCOUNT_BALANCE) < GlobalVariableGet("Target_Balance"))
     {
      if(
         ma_1[0]>ma_1sell_level &&
         ma_2[1]>ma_2sell_level &&
         enve[1]>envelope_sell_level&&
         SymbolPositionsTotal()<tradespersignal&&
         (trade_Type==Both_Type||trade_Type==sell)&&
         ma_2[1]<enve[1]&&
         ma_2[2]>enve[2] &&
         ma_2[0]<enve[0]&&
         previous_loss_count < 4&&
         bar[1].close<bar[1].open&& bar[2].close<bar[2].open
      )
        {
         Print("In Sell Mode");
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
         ma_1[0]<ma_1buy_level&&
         ma_2[1]<ma_2buy_level&&
         enve[1]<envelope_buy_level &&
         SymbolPositionsTotal()<tradespersignal&&
         (trade_Type==Both_Type||trade_Type==buy)&&
         ma_2[0]>enve[0]&&
         ma_2[1]>enve[1]&&
         ma_2[2]<enve[2] &&
         previous_loss_count < 4&&
        bar[1].close>bar[1].open&& bar[2].close>bar[2].open )
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
