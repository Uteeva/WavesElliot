#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

struct SPeackTrough{
   double   Val;
   int      Dir;
   int      Bar;
};

input int                  Period      =  8;
input ENUM_APPLIED_PRICE   Price       =  PRICE_CLOSE;
input int                  MAPeriod       =  8;
input int                  MAShift        =  0;
input ENUM_MA_METHOD       MAMethod       =  MODE_SMA;
input ENUM_APPLIED_PRICE   MAPrice        =  PRICE_CLOSE;
input int                  CCIPeriod      =  8;
input ENUM_APPLIED_PRICE   CCIPrice       =  PRICE_TYPICAL;
input int                  ZZPeriod       =  8;
input bool                 DrawWaves      =  true;          
input color                BuyColor       =  clrRed;
input color                SellColor      =  clrBlueViolet;
input color                TextColor      =  clrBlack;
input int                  WavesWidth     =  3;
input bool                 DrawTarget     =  true;
input int                  ChanelWidth    =  1;
input color                BuyTargetColor =  clrRoyalBlue;
input color                SellTargetColor=  clrPaleVioletRed;
input string               InpFont="Arial";         // Шрифт 
input int                  InpFontSize=10;          // Размер шрифта 
input color                InpColor=clrRed;         // Цвет 


int handle=INVALID_HANDLE;
//--- indicator buffers
double         UpArrowBuffer[];
double         DnArrowBuffer[];
double         UpDotBuffer[];
double         DnDotBuffer[];

SPeackTrough PeackTrough[];
int PreCount;
int CurCount;
int PreDir;
int CurDir;
int PreLastBuySig;
int CurLastBuySig;
int PreLastSellSig;
int CurLastSellSig;
datetime LastTime;

bool _DrawWaves;

int OnInit(){

   handle=iCustom(Symbol(),Period(),"iUniZigZagSW",SrcSelect,
                                             DirSelect,
                                             Period,
                                             Price,
                                             MAPeriod,
                                             MAShift,
                                             MAMethod,
                                             MAPrice,
                                             CCIPeriod,
                                             CCIPrice,
                                             ZZPeriod);
   
   if(handle==INVALID_HANDLE){
      Alert("Error load indicator");
      return(INIT_FAILED);
   }  
  
   SetIndexBuffer(0,UpArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DnArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,UpDotBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,DnDotBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   
   PlotIndexSetInteger(2,PLOT_ARROW,159);
   PlotIndexSetInteger(3,PLOT_ARROW,159);   
   
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);  
   
   if(SrcSelect==Src_HighLow || SrcSelect==Src_Close){
      _DrawWaves=DrawWaves;
   }
   else{
      _DrawWaves=false;
      PlotIndexSetInteger(2,PLOT_LINE_COLOR,clrNONE);
      PlotIndexSetInteger(3,PLOT_LINE_COLOR,clrNONE);      
   }     
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   ObjectsDeleteAll(0,MQLInfoString(MQL_PROGRAM_NAME));
   ChartRedraw(0);
}  
  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   int start;
   
   if(prev_calculated==0){
      start=1;      
      CurCount=0;
      PreCount=0;
      CurDir=0;
      PreDir=0;      
      CurLastBuySig=0;
      PreLastBuySig=0;
      CurLastSellSig=0;
      PreLastSellSig=0;
      LastTime=0;
   }
   else{
      start=prev_calculated-1;
   }
   
   for(int i=start;i<rates_total;i++){
   
      if(time[i]>LastTime){
         LastTime=time[i];
         PreCount=CurCount;
         PreDir=CurDir;
         PreLastBuySig=CurLastBuySig;
         PreLastSellSig=CurLastSellSig;         
      }
      else{
         CurCount=PreCount;
         CurDir=PreDir;
         CurLastBuySig=PreLastBuySig;
         CurLastSellSig=PreLastSellSig;         
      }
   
      UpArrowBuffer[i]=EMPTY_VALUE;
      DnArrowBuffer[i]=EMPTY_VALUE;
      
      UpDotBuffer[i]=EMPTY_VALUE;
      DnDotBuffer[i]=EMPTY_VALUE;    
      
      if(_DrawWaves){
         DeleteObjects(time[i]);
      }  
      
      double hval[1];
      double lval[1];
      
      double zz[1];
      
      // new max      
      
      double lhb[2];
      if(CopyBuffer(handle,4,rates_total-i-1,2,lhb)<=0){
         return(0);
      }
      if(lhb[0]!=lhb[1]){
         if(CopyBuffer(handle,0,rates_total-i-1,1,hval)<=0){
            return(0);
         }      
         if(CurDir==1){
            Upload(i,hval[0]);
         }
         else{
            AddPeack(i,hval[0],1);
         }
         ElliotDn(rates_total,high,time,i);
      }
      
      double llb[2];
      if(CopyBuffer(handle,5,rates_total-i-1,2,llb)<=0){
         return(0);
      }
      if(llb[0]!=llb[1]){
         if(CopyBuffer(handle,1,rates_total-i-1,1,lval)<=0){
            return(0);
         }         
         if(CurDir==-1){
            Upload(i,lval[0]);
         }
         else{
            AddPeack(i,lval[0],-1);
          
         }
         ElliotUp(rates_total,low,time,i);
      }      
   }
   
   if(_DrawWaves){
      ChartRedraw(0);
   }

   return(rates_total);
}
//+------------------------------------------------------------------+

void Upload(int i,double v){
   PeackTrough[CurCount-1].Bar=i;
   PeackTrough[CurCount-1].Val=v;
} 

void AddPeack(int i,double v,int d){
   if(CurCount>=ArraySize(PeackTrough)){
      ArrayResize(PeackTrough,ArraySize(PeackTrough)+1024);
   }
   PeackTrough[CurCount].Dir=d;
   PeackTrough[CurCount].Val=v;
   PeackTrough[CurCount].Bar=i;
   CurCount++;   
   CurDir=d;
} 

void ElliotUp(int rates_total,const double & low[],const datetime & time[],int i){

   if(CurCount<9 || CurDir!=-1){
      return;
   }   
   
   double v1=PeackTrough[CurCount-9].Val;
   double v2=PeackTrough[CurCount-8].Val;
   double v3=PeackTrough[CurCount-7].Val;
   double v4=PeackTrough[CurCount-6].Val;
   double v5=PeackTrough[CurCount-5].Val;
   double v6=PeackTrough[CurCount-4].Val;
   double vA=PeackTrough[CurCount-3].Val;
   double vB=PeackTrough[CurCount-2].Val;
   double vC=PeackTrough[CurCount-1].Val;
   
   
   int i1=PeackTrough[CurCount-9].Bar;
   int i2=PeackTrough[CurCount-8].Bar;               
   int i3=PeackTrough[CurCount-7].Bar;
   int i4=PeackTrough[CurCount-6].Bar;
   int i5=PeackTrough[CurCount-5].Bar;
   int i6=PeackTrough[CurCount-4].Bar;
   int iA=PeackTrough[CurCount-3].Bar;
   int iB=PeackTrough[CurCount-2].Bar;
   int iC=PeackTrough[CurCount-1].Bar;
                  
   if(CurLastBuySig!=iB){
   
      double kanal1=chaneladd(i2,v2,i4,v4,iA);
      double kanal2=chaneladd(i3,v3,i5,v5,iA);
      double kat11=v2-v1;
      int kat12=i2-i1;
      double gip1=sqrt(pow(kat11,2)+pow(kat12,2));
      
      double kat31=v4-v3;
      int kat32=i4-i3;
      double gip3=sqrt(pow(kat31,2)+pow(kat32,2));
      
      double kat51=v6-v5;
      int kat52=i6-i5;
      double gip5=sqrt(pow(kat51,2)+pow(kat52,2));
      
      
      if(v2>v1){
         if(v3>=v1){
            if(v4>=v2){
               if(v5>=v2-0.001){
                  if(gip3>=gip1 || gip3>=gip5){
                  // if(vA>v5){
                    if(vB<v6){
                     if(vC<vA+0.01){
                     CurLastBuySig=iB;
                     if(_DrawWaves){
                        Draw(BuyColor,BuyTargetColor,v1,v2,v3,v4,v5,v6,vA,vB,vC,i1,i2,i3,
                        i4,i5,i6,iA,iB,iC,kanal1,kanal2,time,i,rates_total);
                     }
                     }
                    // }
                     }
                  }
               }
            }
         }
      }
   }
}

void ElliotDn(int rates_total,const double & high[],const datetime & time[],int i){

   if(CurCount<9 || CurDir!=1){ 
      return;
   }

   double v1=PeackTrough[CurCount-9].Val;
   double v2=PeackTrough[CurCount-8].Val;
   double v3=PeackTrough[CurCount-7].Val;
   double v4=PeackTrough[CurCount-6].Val;
   double v5=PeackTrough[CurCount-5].Val;
   double v6=PeackTrough[CurCount-4].Val;
   double vA=PeackTrough[CurCount-3].Val;
   double vB=PeackTrough[CurCount-2].Val;
   double vC=PeackTrough[CurCount-1].Val;
   
   
   int i1=PeackTrough[CurCount-9].Bar;
   int i2=PeackTrough[CurCount-8].Bar;               
   int i3=PeackTrough[CurCount-7].Bar;
   int i4=PeackTrough[CurCount-6].Bar;
   int i5=PeackTrough[CurCount-5].Bar;
   int i6=PeackTrough[CurCount-4].Bar;
   int iA=PeackTrough[CurCount-3].Bar;
   int iB=PeackTrough[CurCount-2].Bar;
   int iC=PeackTrough[CurCount-1].Bar;
   
   if(CurLastSellSig!=iB){
   
         double kanal1=chaneladd(i2,v2,i4,v4,iA);
      double kanal2=chaneladd(i3,v3,i5,v5,iA);
   
      
      double kat11=v2-v1;
      int kat12=i2-i1;
      double gip1=sqrt(pow(kat11,2)+pow(kat12,2));
      
      double kat31=v4-v3;
      int kat32=i4-i3;
      double gip3=sqrt(pow(kat31,2)+pow(kat32,2));
      
      double kat51=v6-v5;
      int kat52=i6-i5;
      double gip5=sqrt(pow(kat51,2)+pow(kat52,2));
      
      
      if(v2<v1){
         if(v3<=v1){
            if(v4<=v2){
               if(v5<=v2+0.001){
                  if(gip3>=gip1 || gip3>=gip5){
                  //  if(vA<v5){
                    if(vB>v6){
                     if(vC>vA-0.01){
                     CurLastSellSig=iB;
                     if(_DrawWaves){
                        Draw(SellColor,SellTargetColor,v1,v2,v3,v4,v5,v6,vA,vB,vC,i1,i2,i3,
                        i4,i5,i6,iA,iB,iC,kanal1,kanal2,time,i,rates_total);
                     }
                     }
                   //  }
                     }
                 }
               }
            }
         }
      }
   }
}

void DeleteObjects(datetime time){
   string prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_"+IntegerToString(time)+"_";
   ObjectDelete(0,prefix+"12");
   ObjectDelete(0,prefix+"23");
   ObjectDelete(0,prefix+"34");
   ObjectDelete(0,prefix+"45");
   ObjectDelete(0,prefix+"56");
   ObjectDelete(0,prefix+"13");
   ObjectDelete(0,prefix+"24"); 
   ObjectDelete(0,prefix+"14");    
   ObjectDelete(0,prefix+"67"); 
   ObjectDelete(0,prefix+"7h");    
}

void Draw( color col,color tcol,double v1,double v2,double v3,double v4,double v5,
           double v6,double vA,double vB,double vC,int i1,
           int i2,int i3,int i4,int i5,int i6,int iA,int iB,int iC,double kanal1,
           double kanal2,const datetime & time[],int i,int rates_total){

   string prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_"+IntegerToString(time[i])+"_";
                    
   Trenddraw(prefix+"12",time[i1],v1,time[i2],v2,col,WavesWidth);
   Trenddraw(prefix+"23",time[i2],v2,time[i3],v3,col,WavesWidth);   
   Trenddraw(prefix+"34",time[i3],v3,time[i4],v4,col,WavesWidth);
   Trenddraw(prefix+"45",time[i4],v4,time[i5],v5,col,WavesWidth);
   Trenddraw(prefix+"56",time[i5],v5,time[i6],v6,col,WavesWidth);
   Trenddraw(prefix+"57",time[i6],v6,time[iA],vA,col,WavesWidth);
   Trenddraw(prefix+"58",time[iA],vA,time[iB],vB,col,WavesWidth);
   Trenddraw(prefix+"59",time[iB],vB,time[iC],vC,col,WavesWidth);
   
   TextCreate(prefix+"67",time[i2],v2,TextColor,ChanelWidth, "1");
   TextCreate(prefix+"68",time[i3],v3,TextColor,ChanelWidth, "2");
   TextCreate(prefix+"69",time[i4],v4,TextColor,ChanelWidth, "3");
   TextCreate(prefix+"70",time[i5],v5,TextColor,ChanelWidth, "4");
   TextCreate(prefix+"71",time[i6],v6,TextColor,ChanelWidth, "5");
   TextCreate(prefix+"72",time[iA],vA,TextColor,ChanelWidth, "A");
   TextCreate(prefix+"80",time[iB],vB,TextColor,ChanelWidth, "B");
   TextCreate(prefix+"81",time[iC],vC,TextColor,ChanelWidth, "C");
   
   ChannelCreate(prefix+"73",time[i2],v2,time[iA],kanal1,time[i3],v3,clrYellowGreen,2); 
   ChannelCreate(prefix+"75",time[i3],v3,time[iA],kanal2,time[i4],v4,clrBlue,2);
}

double chaneladd(double x1,double y1,double x2,double y2,double x3){
   return(y1+(x3-x1)*(y2-y1)/(x2-x1));
}

void Trenddraw( string  aObjName,datetime aTime_1,double   aPrice_1,datetime aTime_2,
                  double   aPrice_2,color    aColor      =  clrRed,  int    aWidth      =  2, string   aText       =  "",
                  int      aWindow     =  0, color aStyle      =  0,int aChartID    =  0,bool     aBack       =  false,bool     aSelectable =  false,
                  bool     aSelected   =  false,long     aTimeFrames =  OBJ_ALL_PERIODS
               ){
   ObjectCreate(aChartID,aObjName,OBJ_TREND,aWindow,aTime_1,aPrice_1,aTime_2,aPrice_2);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_BACK,aBack);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_COLOR,aColor);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_SELECTABLE,aSelectable);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_SELECTED,aSelected);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_TIMEFRAMES,aTimeFrames);
   ObjectSetString(aChartID,aObjName,OBJPROP_TEXT,aText);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_WIDTH,aWidth);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_STYLE,aStyle);
   ObjectMove(aChartID,aObjName,0,aTime_1,aPrice_1);
   ObjectMove(aChartID,aObjName,1,aTime_2,aPrice_2);   
}

void TextCreate(  string   aObjName,     datetime aTime_1,double   aPrice_1,color    aColor      =  clrRed,  int    aWidth      =  1,                 string   aText       =  "",int      aWindow     =  0,color    aStyle      =  0,int      aChartID    =  0,
                  bool     aBack       =  false,bool     aSelectable =  false,bool     aSelected   =  false,
                  long     aTimeFrames =  OBJ_ALL_PERIODS,string   font        =  "Arial", int      font_size   =  10)            
  { 
  
   ObjectCreate(aChartID,aObjName,OBJ_TEXT,aWindow,aTime_1,aPrice_1); 
   ObjectSetString(aChartID,aObjName,OBJPROP_TEXT,aText); 
   ObjectSetString(aChartID,aObjName,OBJPROP_FONT,font); 
   ObjectSetInteger(aChartID,aObjName,OBJPROP_FONTSIZE,font_size); 
   ObjectSetInteger(aChartID,aObjName,OBJPROP_COLOR,aColor); 
  } 
  
  
void ChannelCreate(   string  aObjName,datetime aTime_1,double   aPrice_1,datetime aTime_2,double   aPrice_2,
                  datetime aTime_3,double   aPrice_3,color    aColor      =  clrRed,  int    aWidth      =  1,               
                  bool     aRay_1      =  false,bool     aRay_2      =  false,string   aText       =  "", int      aWindow     =  0, color    aStyle      =  0,
                  int      aChartID    =  0,bool     aBack       =  false,bool     aSelectable =  false,
                  bool     aSelected   =  false,long     aTimeFrames =  OBJ_ALL_PERIODS,bool     ray_right      =  true
               ){
   ObjectCreate(aChartID,aObjName,OBJ_CHANNEL,aWindow,aTime_1,aPrice_1,aTime_2,aPrice_2,aTime_3,aPrice_3);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_BACK,aBack);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_COLOR,aColor);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_SELECTABLE,aSelectable);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_SELECTED,aSelected);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_TIMEFRAMES,aTimeFrames);
   ObjectSetString(aChartID,aObjName,OBJPROP_TEXT,aText);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_WIDTH,aWidth);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_STYLE,aStyle);
   ObjectSetInteger(aChartID,aObjName,OBJPROP_RAY_LEFT,aRay_1);   
}
