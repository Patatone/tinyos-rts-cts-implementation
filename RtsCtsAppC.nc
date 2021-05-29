#include "RtsCts.h"

configuration RtsCtsAppC {}

implementation {

	components MainC, RtsCtsC as App;
	
	components new AMReceiverC(AM_MY_MSG) as MsgReceiver;
	components new AMReceiverC(AM_CTS_MSG) as CtsReceiver;
	components new AMReceiverC(AM_RTS_MSG) as RtsReceiver;
	components new AMReceiverC(AM_REPORT_MSG) as ReportReceiver;
	
	components ActiveMessageC;
	
	components new AMSenderC(AM_MY_MSG) as MsgSender;
	components new AMSenderC(AM_CTS_MSG) as CtsSender;
	components new AMSenderC(AM_RTS_MSG) as RtsSender;
	components new AMSenderC(AM_REPORT_MSG) as ReportSender;
	
	components new TimerMilliC() as EndTimer;
	components new TimerMilliC() as MilliTimer2;
	components new TimerMilliC() as MilliTimer3;
	components new TimerMilliC() as MilliTimer4;
	components new TimerMilliC() as MilliTimer5;
	components new TimerMilliC() as MilliTimer6;


	App.Boot -> MainC.Boot;
	
	App.MsgReceiver -> MsgReceiver;
	App.CtsReceiver -> CtsReceiver;
	App.RtsReceiver -> RtsReceiver;
	App.ReportReceiver -> ReportReceiver;
	
	App.RtsSend -> RtsSender;
	App.CtsSend -> CtsSender;
	App.MsgSend -> MsgSender;
	App.ReportSend -> ReportSender;
	
	App.RtsPacket -> RtsSender;
	App.CtsPacket -> CtsSender;
	App.MsgPacket -> MsgSender;
	App.ReportPacket -> ReportSender;
	
	App.SplitControl -> ActiveMessageC;
	App.EndTimer -> EndTimer;
	App.MilliTimer2 -> MilliTimer2;
	App.MilliTimer3 -> MilliTimer3;
	App.MilliTimer4 -> MilliTimer4;
	App.MilliTimer5 -> MilliTimer5;
	App.MilliTimer6 -> MilliTimer6;
}

