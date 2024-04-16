//+------------------------------------------------------------------+
//|                                                TrediquePanel.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link "https://www.tredique.com"
#property version "1.00"

#include <CGraphicalPanel.mqh>

//#include <Controls\Dialog.mqh>

//#include <Controls\Button.mqh>

//#define PANEL_NAME "Tredique App"
//#define PANEL_WIDTH 200
//#define PANEL_HEIGHT 200

//CAppDialog app;
//CButton btn_buy;
//CButton btn_sell;
//CButton btn_buy_stop;
//CButton btn_sell_stop;
//CButton btn_buy_limit;
//CButton btn_sell_limit;

CGraphicalPanel panel;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---
  //app.Create(0, PANEL_NAME, 0, 20, 20, PANEL_WIDTH, PANEL_HEIGHT);
  if(!panel.Oninit()){return INIT_FAILED;}
  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //destrop
  panel.Destroy(reason);

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  //---
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Chart Event handler                                              |
//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){
panel.PanelChartEvent(id,lparam,dparam,sparam);
}