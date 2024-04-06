//+------------------------------------------------------------------+
//|                                            PivotPointProwler.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

enum ENUM_OPTION
{
  YES, // Yes
  NO,  // No
  BUY,
  SELL,
  BUY_LIMIT,
  SELL_LIMIT,
  BUY_STOP,
  SELL_STOP,
};

input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input double LotSize = 0.1;
input double StopLoss = 20.0;   // in pips
input double TakeProfit = 40.0; // in pips
input string Address = "";
input int Port = 6000;
input ENUM_OPTION manualTrade = YES; // Manual Trading
input int expirationTime = 1;        // Expiration in minutes

// Global variables for tracking candle information
MqlRates candles[];
int barsTotal;

bool ExtTLS = false;
datetime open_binary;
string url = Address;
string headers;
string BtnSend = "SendButton";
string BtnPut = "putButton";
string EditPrice = "EditPrice";
string tradeOption = "";
bool isPremium = false; // Premium

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  // For trading buttons
  if (manualTrade == YES)
  {
    createButton(BtnSend, "SendButton", 20, 200, clrAntiqueWhite, clrBlueViolet);

    // For selecting trade type
    createButton("BuyLimitButton", "Buy Limit", 200, 200, clrAntiqueWhite, clrGreen);
    createButton("SellLimitButton", "Sell Limit", 200, 250, clrAntiqueWhite, clrRed);
    createButton("BuyStopButton", "Buy Stop", 200, 300, clrAntiqueWhite, clrGreen);
    createButton("SellStopButton", "Sell Stop", 200, 350, clrAntiqueWhite, clrRed);
    createButton("BuyButton", "Buy", 200, 400, clrAntiqueWhite, clrGreen);
    createButton("SellButton", "Sell", 200, 450, clrAntiqueWhite, clrRed);

    // For premium option
    createButton("PremiumToggle", "Premium: OFF", 400, 200, clrAntiqueWhite, clrGreen);

    // Create input field for price
    ObjectCreate(0, EditPrice, OBJ_EDIT, 0, 0, 0);
    ObjectSetInteger(0, EditPrice, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, EditPrice, OBJPROP_XDISTANCE, 400);
    ObjectSetInteger(0, EditPrice, OBJPROP_YDISTANCE, 250);
    ObjectSetInteger(0, EditPrice, OBJPROP_XSIZE, 100);
    ObjectSetInteger(0, EditPrice, OBJPROP_YSIZE, 20);
    ObjectSetInteger(0, EditPrice, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, EditPrice, OBJPROP_BORDER_COLOR, clrBlack);

    ChartRedraw();
  }

  // Ensure candles[] array is accessed in reverse
  ArraySetAsSeries(candles, true);
  // Pre-load candle data
  if (!CopyRates(_Symbol, timeframe, 0, 4, candles))
  {
    Print("Error loading candle data: ", GetLastError());
    return INIT_FAILED;
  }
  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  int bars = iBars(_Symbol, timeframe);
  double currentPrice = SymbolInfoDouble(NULL, SYMBOL_BID);
  datetime curTime = TimeCurrent();
  if (tradeOption == "" && open_binary < curTime)
  {
    ObjectSetInteger(0, "SendButton", OBJPROP_BGCOLOR, clrBlueViolet);
  }

  if (barsTotal != bars)
  {
    // If number of bars is different update total bars
    barsTotal = bars;

    // Refresh candle data
    if (!CopyRates(_Symbol, timeframe, 0, 4, candles))
    {
      Print("Error refreshing candle data: ", GetLastError());
      return;
    }
    // Check conditions for a buy entry
    if (isBuySignal())
    {
      // sendSignal("buy");
      tradeOption = "BUY";
      sendSignalHTTPRequest(currentPrice); // Use the WebRequest method
      Alert("Buy Signal for " + _Symbol);
    }
    // Check conditions for a sell entry
    if (isSellSignal())
    {
      // sendSignal("sell", currentPrice);
      tradeOption = "SELL";
      sendSignalHTTPRequest(currentPrice); // Use the WebRequest method
      Alert("Sell Signal for " + _Symbol);
    }
  }
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
  double currentPrice = SymbolInfoDouble(NULL, SYMBOL_BID);

  if (id == CHARTEVENT_OBJECT_CLICK)
  {
    if (sparam == "SendButton")
    {
      sendSignalHTTPRequest(currentPrice); // Use the WebRequest method
      ObjectSetInteger(0, BtnSend, OBJPROP_STATE, false);
      ObjectSetInteger(0, BtnSend, OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "BuyLimitButton")
    {
      tradeOption = "BUY LIMIT";
      ObjectSetInteger(0, "BuyLimitButton", OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "SellLimitButton")
    {
      tradeOption = "SELL LIMIT";
      ObjectSetInteger(0, "SellLimitButton", OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "BuyStopButton")
    {
      tradeOption = "BUY STOP";
      ObjectSetInteger(0, "BuyStopButton", OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "SellStopButton")
    {
      tradeOption = "SELL STOP";
      ObjectSetInteger(0, "SellStopButton", OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "BuyButton")
    {
      tradeOption = "BUY";
      ObjectSetInteger(0, "BuyButton", OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "SellButton")
    {
      tradeOption = "SELL";
      ObjectSetInteger(0, "SellButton", OBJPROP_BGCOLOR, clrRosyBrown);
    }
    else if (sparam == "PremiumToggle")
    {
      isPremium = (isPremium == true) ? false : true;
      string buttonText = (isPremium == true) ? "Premium: ON" : "Premium: OFF";
      ObjectSetString(0, "PremiumToggle", OBJPROP_TEXT, buttonText);
    }
  }
}

//+------------------------------------------------------------------+
//| Check if current conditions match sell signal criteria           |
//+------------------------------------------------------------------+
bool isSellSignal()
{
  // Conditions based on your criteria
  for (int i = 1; i <= 3; i++)
  {
    if (!(candles[i].close > candles[i].open && candles[i].high > candles[i].close))
    {
      return false;
    }
  }
  if (candles[2].close < candles[3].high && candles[1].close < candles[3].high && candles[1].close < candles[2].high)
  {
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//| Check if current conditions match buy signal criteria            |
//+------------------------------------------------------------------+
bool isBuySignal()
{
  // Conditions for a bullish reversal
  for (int i = 1; i <= 3; i++)
  {
    if (!(candles[i].close < candles[i].open && candles[i].low < candles[i].close))
    {
      return false;
    }
  }
  if (candles[2].close > candles[3].low && candles[1].close > candles[3].low && candles[1].close > candles[2].low)
  {
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//|            SEND SIGNAL                                                      |
//+------------------------------------------------------------------+
void sendSignal(string tradeOption)
{
  datetime currentTime = TimeCurrent();
  // Avoid sending signals too frequently
  if (open_binary >= currentTime)
  {
    return;
  }

  open_binary = currentTime + 300; // Next signal not before 5 minutes
  int socket = SocketCreate();

  if (socket == INVALID_HANDLE)
  {
    Print("Failed to create a socket, error ", GetLastError());
    return;
  }

  if (!SocketConnect(socket, Address, Port, 1000))
  {
    Print("Connection to ", Address, ":", Port, " failed, error ", GetLastError());
    SocketClose(socket); // Ensure socket is closed on failure
    return;
  }

  // Display certificate information if connection is secure
  if (displayTlsCertificate(socket))
  {
    ExtTLS = true;
  }

  // Send the signal to the server
  if (!sendSignalRequest(socket, tradeOption))
  {
    Print("Failed to send signal request for ", tradeOption, ", error ", GetLastError());
  }

  SocketClose(socket); // Close the socket after use
}

//+------------------------------------------------------------------+
//| Display TLS certificate information                              |
//+------------------------------------------------------------------+
bool displayTlsCertificate(int socket)
{
  string subject, issuer, serial, thumbprint;
  datetime expiration;

  if (!SocketTlsCertificate(socket, subject, issuer, serial, thumbprint, expiration))
  {
    return false; // No certificate information available
  }

  Print("TLS certificate:");
  Print("   Owner:  ", subject);
  Print("   Issuer:  ", issuer);
  Print("   Number:  ", serial);
  Print("   Thumbprint: ", thumbprint);
  Print("   Expiration: ", expiration);
  return true;
}

//+------------------------------------------------------------------+
//| Send signal request to the server                                |
//+------------------------------------------------------------------+
bool sendSignalRequest(int socket, string tradeOption)
{
  string request = StringFormat("{\"symbol\":\"%s\",\"trade_option\":\"%s\",\"msg_type\":\"signal\"}", _Symbol, tradeOption);

  if (!HTTPSend(socket, request))
  {
    return false; // Failed to send the request
  }

  Print("GET request sent for ", tradeOption);
  return HTTPRecv(socket, 1000); // Attempt to receive response
}
//+------------------------------------------------------------------+
//| Read server response within a given timeout                      |
//+------------------------------------------------------------------+
bool HTTPRecv(int socket, uint timeout)
{
  char responseBuffer[];
  string accumulatedResponse = "";
  uint timeoutDeadline = GetTickCount() + timeout;

  // Continuously read data until the timeout is reached
  while (GetTickCount() < timeoutDeadline && !IsStopped())
  {
    uint readableLength = SocketIsReadable(socket);
    if (readableLength > 0)
    {
      int bytesRead = readDataFromSocket(socket, responseBuffer, readableLength, timeout);
      if (bytesRead > 0)
      {
        accumulatedResponse += CharArrayToString(responseBuffer, 0, bytesRead);
        if (hasReceivedCompleteHeader(accumulatedResponse))
        {
          return true;
        }
      }
    }
  }
  return false;
}

//+------------------------------------------------------------------+
//| Attempt to read data from the socket                             |
//+------------------------------------------------------------------+
int readDataFromSocket(int socket, char &buffer[], uint length, uint timeout)
{
  return ExtTLS ? SocketTlsRead(socket, buffer, length) : SocketRead(socket, buffer, length, timeout);
}

//+------------------------------------------------------------------+
//| Check if the HTTP response header has been fully received        |
//+------------------------------------------------------------------+
bool hasReceivedCompleteHeader(const string &response)
{
  int headerEndIndex = StringFind(response, "\r\n\r\n");
  if (headerEndIndex > 0)
  {
    Print("HTTP answer header received:");
    Print(StringSubstr(response, 0, headerEndIndex));
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket, string request)
{
  char requestArray[];
  int requestLength = StringToCharArray(request, requestArray) - 1; // Convert and get length

  if (requestLength < 0)
  {
    Print("Error converting request string to char array.");
    return false;
  }

  // Determine and execute the appropriate sending method based on connection type
  return sendRequestBasedOnConnectionType(socket, requestArray, requestLength);
}

//+------------------------------------------------------------------+
//| Determine and execute the sending method based on connection type|
//+------------------------------------------------------------------+
bool sendRequestBasedOnConnectionType(int socket, char &requestArray[], int requestLength)
{
  int sentLength = ExtTLS ? SocketTlsSend(socket, requestArray, requestLength)
                          : SocketSend(socket, requestArray, requestLength);

  if (sentLength != requestLength)
  {
    Print("Error sending request: Sent length does not match request length.");
    return false;
  }

  return true; // Successfully sent the entire request
}

void sendSignalHTTPRequest(double entryPrice)
{
  if (tradeOption != "")
  {
    datetime currentTime = TimeCurrent();
    // Avoid sending signals too frequently

    // if (open_binary >= currentTime)
    // {
    //   return;
    // }

    open_binary = currentTime + 300; // Next signal not before 5 minutes

    char post[];          // The request to send to the server
    char result[];        // The response from the server
    string resultHeaders; // The response headers from the server

    // Create the string json to send to the server
    string requestData;

    StringConcatenate(
        requestData,
        "{\"symbol\":\"", _Symbol,
        "\",\"price\":", DoubleToString(entryPrice),
        ",\"type\":\"", tradeOption,
        "\",\"isPremium\":", isPremium ? "true" : "false",
        ",\"expiration\":\"", IntegerToString(expirationTime),
        "\"}");

    StringToCharArray(requestData, post, 0, StringLen(requestData));

    int response = WebRequest(
        "POST",                           // HTTP method
        url,                              // URL to the server
        "Content-Type: application/json", // HTTP headers
        3000,                             // Timeout in milliseconds to wait for response from server (3secs)
        post,                             // The request data to send to the server
        result,                           // The response from the server
        resultHeaders                     // The response headers to the server
    );

    if (response == 200)
    {
      Print(__FUNCTION__, " Signal Send Successfully: ", CharArrayToString(result));
      ResetValues();
    }
    else
    {
      Print(__FUNCTION__, " Signal Send Failed: ", CharArrayToString(result));
    }
  }
}

//+------------------------------------------------------------------+
//| Button to display on chart                                       |
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
//| Reset button colors and variables to default state               |
//+------------------------------------------------------------------+
void ResetValues()
{
  // Reset button colors to default
  ObjectSetInteger(0, "BuyLimitButton", OBJPROP_BGCOLOR, clrGreen);
  ObjectSetInteger(0, "SellLimitButton", OBJPROP_BGCOLOR, clrRed);
  ObjectSetInteger(0, "BuyStopButton", OBJPROP_BGCOLOR, clrGreen);
  ObjectSetInteger(0, "SellStopButton", OBJPROP_BGCOLOR, clrRed);
  ObjectSetInteger(0, "BuyButton", OBJPROP_BGCOLOR, clrGreen);
  ObjectSetInteger(0, "SellButton", OBJPROP_BGCOLOR, clrRed);

  // Reset trade option to default
  tradeOption = "";
  // Reset Premium to default
  isPremium = false;
  string buttonText = (isPremium == true) ? "Premium: ON" : "Premium: OFF";
  ObjectSetString(0, "PremiumToggle", OBJPROP_TEXT, buttonText);
}