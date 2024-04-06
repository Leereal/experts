//+------------------------------------------------------------------+
//|                                            PivotPointProwler.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input double LotSize = 0.1;
input double StopLoss = 20.0; // in pips
input double TakeProfit = 40.0; // in pips

// Global variables for tracking candle information
MqlRates candles[];
int barsTotal;

input string Address = "192.168.0.112";
input int Port = 6000;
bool ExtTLS = false;
datetime open_binary;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
  // Ensure candles[] array is accessed in reverse
  ArraySetAsSeries(candles, true);
  // Pre-load candle data
  if (!CopyRates(_Symbol, timeframe, 0, 4, candles)) {
    Print("Error loading candle data: ", GetLastError());
    return INIT_FAILED;
  }
  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   int bars = iBars(_Symbol,timeframe);
   
   if(barsTotal != bars){
     //If number of bars is different update total bars
     barsTotal = bars;
     
     // Refresh candle data
     if (!CopyRates(_Symbol, timeframe, 0, 4, candles)) {
       Print("Error refreshing candle data: ", GetLastError());
       return;
     }
     // Check conditions for a buy entry
     if (isBuySignal()) {
       sendSignal("buy");
       Alert("Buy Signal for "+_Symbol);
     }
     // Check conditions for a sell entry
     if (isSellSignal()) {
       sendSignal("sell");
       Alert("Sell Signal for "+_Symbol);
     } 
   }
}

//+------------------------------------------------------------------+
//| Check if current conditions match sell signal criteria           |
//+------------------------------------------------------------------+
bool isSellSignal() {
  // Conditions based on your criteria
  for (int i = 1; i <= 3; i++) {
    if (!(candles[i].close > candles[i].open && candles[i].high > candles[i].close)) {
      return false;
    }
  }
  if (candles[2].close < candles[3].high && candles[1].close < candles[3].high && candles[1].close < candles[2].high) {
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//| Check if current conditions match buy signal criteria            |
//+------------------------------------------------------------------+
bool isBuySignal() {
  // Conditions for a bullish reversal
  for (int i = 1; i <= 3; i++) {
    if (!(candles[i].close < candles[i].open && candles[i].low < candles[i].close)) {
      return false;
    }
  }
  if (candles[2].close > candles[3].low && candles[1].close > candles[3].low && candles[1].close > candles[2].low) {
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//|            SEND SIGNAL                                                      |
//+------------------------------------------------------------------+
void sendSignal(string tradeOption) {
  datetime currentTime = TimeCurrent();
  // Avoid sending signals too frequently
  if (open_binary >= currentTime) {
    return;
  }

  open_binary = currentTime + 300; // Next signal not before 5 minutes
  int socket = SocketCreate();

  if (socket == INVALID_HANDLE) {
    Print("Failed to create a socket, error ", GetLastError());
    return;
  }

  if (!SocketConnect(socket, Address, Port, 1000)) {
    Print("Connection to ", Address, ":", Port, " failed, error ", GetLastError());
    SocketClose(socket); // Ensure socket is closed on failure
    return;
  }

  // Display certificate information if connection is secure
  if (displayTlsCertificate(socket)) {
    ExtTLS = true;
  }

  // Send the signal to the server
  if (!sendSignalRequest(socket, tradeOption)) {
    Print("Failed to send signal request for ", tradeOption, ", error ", GetLastError());
  }

  SocketClose(socket); // Close the socket after use
}

//+------------------------------------------------------------------+
//| Display TLS certificate information                              |
//+------------------------------------------------------------------+
bool displayTlsCertificate(int socket) {
  string subject, issuer, serial, thumbprint;
  datetime expiration;
  
  if (!SocketTlsCertificate(socket, subject, issuer, serial, thumbprint, expiration)) {
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
bool sendSignalRequest(int socket, string tradeOption) {
  string request = StringFormat("{\"symbol\":\"%s\",\"trade_option\":\"%s\",\"msg_type\":\"signal\"}", _Symbol, tradeOption);

  if (!HTTPSend(socket, request)) {
    return false; // Failed to send the request
  }

  Print("GET request sent for ", tradeOption);
  return HTTPRecv(socket, 1000); // Attempt to receive response
}
//+------------------------------------------------------------------+
//| Read server response within a given timeout                      |
//+------------------------------------------------------------------+
bool HTTPRecv(int socket, uint timeout) {
  char responseBuffer[];
  string accumulatedResponse = "";
  uint timeoutDeadline = GetTickCount() + timeout;

  // Continuously read data until the timeout is reached
  while (GetTickCount() < timeoutDeadline && !IsStopped()) {
    uint readableLength = SocketIsReadable(socket);
    if (readableLength > 0) {
      int bytesRead = readDataFromSocket(socket, responseBuffer, readableLength, timeout);
      if (bytesRead > 0) {
        accumulatedResponse += CharArrayToString(responseBuffer, 0, bytesRead);
        if (hasReceivedCompleteHeader(accumulatedResponse)) {
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
int readDataFromSocket(int socket, char &buffer[], uint length, uint timeout) {
  return ExtTLS ? SocketTlsRead(socket, buffer, length) : SocketRead(socket, buffer, length, timeout);
}

//+------------------------------------------------------------------+
//| Check if the HTTP response header has been fully received        |
//+------------------------------------------------------------------+
bool hasReceivedCompleteHeader(const string &response) {
  int headerEndIndex = StringFind(response, "\r\n\r\n");
  if (headerEndIndex > 0) {
    Print("HTTP answer header received:");
    Print(StringSubstr(response, 0, headerEndIndex));
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket, string request) {
  char requestArray[];
  int requestLength = StringToCharArray(request, requestArray) - 1; // Convert and get length
  
  if (requestLength < 0) {
    Print("Error converting request string to char array.");
    return false;
  }

  // Determine and execute the appropriate sending method based on connection type
  return sendRequestBasedOnConnectionType(socket, requestArray, requestLength);
}

//+------------------------------------------------------------------+
//| Determine and execute the sending method based on connection type|
//+------------------------------------------------------------------+
bool sendRequestBasedOnConnectionType(int socket, char &requestArray[], int requestLength) {
  int sentLength = ExtTLS ? SocketTlsSend(socket, requestArray, requestLength) 
                          : SocketSend(socket, requestArray, requestLength);
                          
  if (sentLength != requestLength) {
    Print("Error sending request: Sent length does not match request length.");
    return false;
  }
  
  return true; // Successfully sent the entire request
}
