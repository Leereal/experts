//+------------------------------------------------------------------+
//|                                                       Trenda.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;
enum ENUM_OPTION
{
  YES, // Yes
  NO,  // No
};
input string NoteSocket = "<=== INPUTS ===>";
input int shoulder = 50;
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input double start_balance = 20;
input double take_profit = 6000;
input double stop_loss = 2000;
input double percentage_risk = 10;

input string Trading = "<=== TRADING SETTINGS ===>";
input ENUM_OPTION autoTrade = NO;    // Auto Trading
input ENUM_OPTION autoDraw = NO;     // Auto Draw
input ENUM_OPTION manualTrade = YES; // Manual Trading

double LotSize = 0.1;                                      // replace with your lot size
double TargetProfit = 10.0;                                // replace with your target profit amount
double EntryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID); // get the current bid price as

int barsTotal;
double lastBid;
MqlRates bar[];
string BtnCall = "callButton";
string BtnPut = "putButton";

input string Tcoment = "BLBot";
datetime open_binary;
int socket; // Socket handle
input string Address = "192.168.0.112";
input int Port = 6000;
bool ExtTLS = false;
//+----------------------------
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
  // Reverse the order of the array such that new price is at index zero and previous at index 1
  ArraySetAsSeries(bar, true);

  // For trading buttons
  if (manualTrade == YES)
  {
    createButton(BtnCall, "CALL", 20, 200, clrAntiqueWhite, clrGreen);
    createButton(BtnPut, "PUT", 20, 300, clrAntiqueWhite, clrRed);
    ChartRedraw();
  }

  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Delete all object on chart after removing the EA
  // ObjectsDeleteAll(0);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  // Draw trendline after every 5 minute candle
  int bars = iBars(_Symbol, timeframe);
  double ask = SymbolInfoDouble(NULL, SYMBOL_ASK);
  double bid = SymbolInfoDouble(NULL, SYMBOL_BID);
  CopyRates(_Symbol, PERIOD_CURRENT, 0, 10, bar);
  double l_c = iClose(NULL, PERIOD_CURRENT, 1);

  if (barsTotal != bars)
  {
    // If number of bars is different update total bars
    barsTotal = bars;
    int bar1;
    int bar2;

    if (autoDraw == YES) // If user wants bot to draw trendlines
    {
      // Calculating or getting the highest price
      bar1 = FindPeak(MODE_HIGH, shoulder, 0);
      bar2 = FindPeak(MODE_HIGH, shoulder, bar1 + 1);

      // Drawing top trendline
      ObjectDelete(0, "UpperTrendLine");
      ObjectCreate(0, "UpperTrendLine", OBJ_TREND, 0, iTime(Symbol(), timeframe, bar2), iHigh(Symbol(), timeframe, bar2), iTime(Symbol(), timeframe, bar1), iHigh(Symbol(), timeframe, bar1));
      ObjectSetInteger(0, "UpperTrendLine", OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, "UpperTrendLine", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, "UpperTrendLine", OBJPROP_RAY_RIGHT, true);

      // Calculate the lowest price
      bar1 = FindPeak(MODE_LOW, shoulder, 0);
      bar2 = FindPeak(MODE_LOW, shoulder, bar1 + 1);

      // Draw bottom trendline
      ObjectDelete(0, "LowerTrendLine");
      ObjectCreate(0, "LowerTrendLine", OBJ_TREND, 0, iTime(Symbol(), timeframe, bar2), iLow(Symbol(), timeframe, bar2), iTime(Symbol(), timeframe, bar1), iLow(Symbol(), timeframe, bar1));
      ObjectSetInteger(0, "LowerTrendLine", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "LowerTrendLine", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, "LowerTrendLine", OBJPROP_RAY_RIGHT, true);
    }
  }

  // Buy
  // Current trendline price when using autodraw
  if (autoDraw == YES)
  {
    double currentUpperTrendLinePrice = ObjectGetValueByTime(0, "UpperTrendLine", TimeCurrent(), 0);

    long digits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    // Round the price to the current symbol digits
    currentUpperTrendLinePrice = NormalizeDouble(currentUpperTrendLinePrice, (int)digits);

    if (bid <= currentUpperTrendLinePrice && l_c >= currentUpperTrendLinePrice)
    {
      Alert("Buy Signal for " + _Symbol);
      // Draw Arrow
      ObjectCreate(0, "BuyArrow" + TimeToString(bar[1].time), OBJ_ARROW, 0, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_ARROWCODE, 233);     // Set the arrow code
      ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_TIME, bar[0].time);  // Set time
      ObjectSetDouble(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_PRICE, bar[0].close); // Set price
      ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_COLOR, clrBlueViolet);
      ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_WIDTH, 3);

      // Delete the trendline
      ObjectDelete(0, "UpperTrendLine");
      // if(autoTrade == YES)
      //{
      // Place trades
      // sendSignal("buy");
      // }
    }

    // Sell
    double currentLowerTrendLinePrice = ObjectGetValueByTime(0, "LowerTrendLine", TimeCurrent(), 0);
    // Round the price to the current symbol digits
    currentLowerTrendLinePrice = NormalizeDouble(currentLowerTrendLinePrice, (int)digits);

    if (ask >= currentLowerTrendLinePrice && l_c <= currentLowerTrendLinePrice)
    {
      Alert("Sell Signal for " + _Symbol);

      // Draw Arrow
      ObjectCreate(0, "SellArrow" + TimeToString(bar[1].time), OBJ_ARROW, 0, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_ARROWCODE, 234);     // Set the arrow code
      ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_TIME, bar[0].time);  // Set time
      ObjectSetDouble(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_PRICE, bar[0].close); // Set price
      ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_WIDTH, 3);

      // Delete the trendline
      ObjectDelete(0, "LowerTrendLine");
      // if(autoTrade =='YES)
      //{
      // Place trades
      // sendSignal("sell");
      // }
    }
  }
  if (autoDraw == NO)
  {
    for (int i = ObjectsTotal(0, 0, OBJ_TREND) - 1; i >= 0; i--)
    {
      string name = ObjectName(0, i, 0, OBJ_TREND);
      if (StringFind(name, "Trendline") > -1)
      {

        // double price = ObjectGetDouble(0,name,OBJP//ROP_PRICE);
        datetime time = TimeCurrent();
        double price = ObjectGetValueByTime(0, name, time);
        color clr = (color)ObjectGetInteger(0, name, OBJPROP_COLOR);

        if (clr == clrGreen)
        {
          if (bid < price && l_c >= price)
          {

            ObjectDelete(0, name);
            Alert("Buy Signal for " + _Symbol);

            // MT5 Buy
            double calculated_profit = percentage_risk / 100 * start_balance * 3;
            double calculated_lot = calculated_profit / take_profit / _Point;
            double sl = ask - stop_loss * _Point;   // Stop Loss
            double tp = ask + take_profit * _Point; // Take Profit
            trade.Buy(calculated_lot, NULL, ask, sl, tp, Tcoment);
            Print(_Symbol, " : ", _Point);
            Print("Calculated Profit : ", calculated_profit);
            Print("SL : ", sl);
            Print("TP : ", tp);
            Print("Calculated Lot : ", calculated_lot);

            // Draw Arrow
            ObjectCreate(0, "BuyArrow" + TimeToString(bar[1].time), OBJ_ARROW, 0, 0, 0, 0, 0, 0);
            ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_ARROWCODE, 233);     // Set the arrow code
            ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_TIME, bar[0].time);  // Set time
            ObjectSetDouble(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_PRICE, bar[0].close); // Set price
            ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, "BuyArrow" + TimeToString(bar[1].time), OBJPROP_WIDTH, 3);
          }
        }
        else if (clr == clrRed)
        {
          if (bid > price && l_c <= price)
          {

            ObjectDelete(0, name);
            Alert("Sell Signal for " + _Symbol);
            // Buy on deriv api
            // sendSignal("buy");

            // MT5 Sell
            double calculated_profit = percentage_risk / 100 * start_balance * 3;
            double calculated_lot = calculated_profit / take_profit / _Point;
            double sl = bid + stop_loss * _Point;   // Stop Loss
            double tp = bid - take_profit * _Point; // Take Profit
            trade.Sell(calculated_lot, NULL, bid, sl, tp, Tcoment);
            Print(_Symbol, " : ", _Point);
            Print("Calculated Profit : ", calculated_profit);
            Print("SL : ", sl);
            Print("TP : ", tp);
            Print("Calculated Lot : ", calculated_lot);
            // Draw Arrow
            ObjectCreate(0, "SellArrow" + TimeToString(bar[1].time), OBJ_ARROW, 0, 0, 0, 0, 0, 0);
            ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_ARROWCODE, 234);     // Set the arrow code
            ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_TIME, bar[0].time);  // Set time
            ObjectSetDouble(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_PRICE, bar[0].close); // Set price
            ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, "SellArrow" + TimeToString(bar[1].time), OBJPROP_WIDTH, 3);
          }
        }
      }
    }
  }
  // Set Last bid price
  lastBid = bid;
}
//+----------------------------------------------------------------+
//|                                                                |
//+----------------------------------------------------------------+
int FindPeak(int mode, int count, int startBar)
{
  if (mode != MODE_HIGH && mode != MODE_LOW)
    return (-1);

  int currentBar = startBar;
  int foundBar = FindNextPeak(mode, count * 2 + 1, currentBar - count);
  while (foundBar != currentBar)
  {
    currentBar = FindNextPeak(mode, count, currentBar + 1);
    foundBar = FindNextPeak(mode, count * 2 + 1, currentBar - count);
  }
  return (currentBar);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int FindNextPeak(int mode, int count, int startBar)
{
  if (startBar < 0)
  {
    count += startBar;
    startBar = 0;
  }
  return ((mode == MODE_HIGH) ? iHighest(Symbol(), timeframe, (ENUM_SERIESMODE)mode, count, startBar) : iLowest(Symbol(), timeframe, (ENUM_SERIESMODE)mode, count, startBar));
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void OnChartEvent(
    const int id,         // event ID
    const long &lparam,   // long type event parameter
    const double &dparam, // double type event parameter
    const string &sparam  // string type event parameter
)
{
  if (id == CHARTEVENT_OBJECT_CLICK)
  {
    if (sparam == BtnCall)
    {
      sendSignal("buy");
      ObjectSetInteger(0, BtnCall, OBJPROP_STATE, false);
    }
    if (sparam == BtnPut)
    {
      sendSignal("sell");
      ObjectSetInteger(0, BtnPut, OBJPROP_STATE, false);
    }
  }
}
//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket, string request)
{
  char req[];
  int len = StringToCharArray(request, req) - 1;
  if (len < 0)
    return (false);
  //--- if secure TLS connection is used via the port 443
  if (ExtTLS)
    return (SocketTlsSend(socket, req, len) == len);
  //--- if standard TCP connection is used
  return (SocketSend(socket, req, len) == len);
}
//+------------------------------------------------------------------+
//| Read server response                                             |
//+------------------------------------------------------------------+
bool HTTPRecv(int socket, uint timeout)
{
  char rsp[];
  string result;
  uint timeout_check = GetTickCount() + timeout;
  //--- read data from sockets till they are still present but not longer than timeout
  do
  {
    uint len = SocketIsReadable(socket);
    if (len)
    {
      int rsp_len;
      //--- various reading commands depending on whether the connection is secure or not
      if (ExtTLS)
        rsp_len = SocketTlsRead(socket, rsp, len);
      else
        rsp_len = SocketRead(socket, rsp, len, timeout);
      //--- analyze the response
      if (rsp_len > 0)
      {
        result += CharArrayToString(rsp, 0, rsp_len);
        //--- print only the response header
        int header_end = StringFind(result, "\r\n\r\n");
        if (header_end > 0)
        {
          Print("HTTP answer header received:");
          Print(StringSubstr(result, 0, header_end));
          return (true);
        }
      }
    }
  } while (GetTickCount() < timeout_check && !IsStopped());
  return (false);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendSignal(string trade_option)
{
  // if(trade_option=='buy'){

  //}
  datetime TimeNow = TimeCurrent();
  if (open_binary < TimeNow)
  {
    open_binary = TimeNow + 300;
    socket = SocketCreate();
    //--- check the handle
    if (socket != INVALID_HANDLE)
    {
      //--- connect if all is well
      if (SocketConnect(socket, Address, Port, 1000))
      {
        Print("Established connection to ", Address, ":", Port);

        string subject, issuer, serial, thumbprint;
        datetime expiration;
        //--- if connection is secured by the certificate, display its data
        if (SocketTlsCertificate(socket, subject, issuer, serial, thumbprint, expiration))
        {
          Print("TLS certificate:");
          Print("   Owner:  ", subject);
          Print("   Issuer:  ", issuer);
          Print("   Number:     ", serial);
          Print("   Print: ", thumbprint);
          Print("   Expiration: ", expiration);
          ExtTLS = true;
        }
        //--- send GET request to the server
        string msg;
        StringConcatenate(msg, "{\"symbol\":\"", _Symbol, "\",", "\"trade_option\":\"", trade_option, "\",\"msg_type\":\"signal\"}");
        // string signal =  "{\"symbol\":\"",_Symbol,"\",","\"trade_option\":\"",trade_option,"\",\"msg_type\":\"signal\"}");
        if (HTTPSend(socket, msg))
        {
          Print("GET request sent");
          //--- read the response
          if (!HTTPRecv(socket, 1000))
            Print("Failed to get a response, error ", GetLastError());
        }
        else
          Print("Failed to send GET request, error ", GetLastError());
      }
      else
      {
        Print("Connection to ", Address, ":", Port, " failed, error ", GetLastError());
      }
      //--- close a socket after using
      SocketClose(socket);
    }
    else
      Print("Failed to create a socket, error ", GetLastError());
  }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int x, int y, color clrTxt, color clrBg)
{
  //--- reset the error value
  ResetLastError();
  //--- create the button
  if (!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0))
  {
    Print(__FUNCTION__,
          ": failed to create the button! Error code = ", GetLastError());
    return (false);
  }
  //--- set button coordinates
  ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
  ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
  //--- set button size
  ObjectSetInteger(0, objName, OBJPROP_XSIZE, 150);
  ObjectSetInteger(0, objName, OBJPROP_YSIZE, 50);
  //--- set the chart's corner, relative to which point coordinates are defined
  ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
  //--- set the text
  ObjectSetString(0, objName, OBJPROP_TEXT, text);

  ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 12);
  //--- set text color
  ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
  //--- set background color
  ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBg);
  //--- set border color
  ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrAliceBlue);
  //--- display in the foreground (false) or background (true)
  ObjectSetInteger(0, objName, OBJPROP_BACK, false);
  //--- set button state
  ObjectSetInteger(0, objName, OBJPROP_STATE, false);
  //--- enable (true) or disable (false) the mode of moving the button by mouse
  ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
  //--- hide (true) or display (false) graphical object name in the object list
  ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
  //--- successful execution
  return (true);
}
//+------------------------------------------------------------------+
void buyEntry()
{
}
//+------------------------------------------------------------------+