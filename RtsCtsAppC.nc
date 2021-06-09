#include "RtsCts.h"

configuration RtsCtsAppC {}

implementation {

	components MainC, RtsCtsC as App;
	
	components new AMReceiverC(AM_MY_MSG) as MsgReceiver;
	components new AMReceiverC(AM_RTS_CTS_MSG) as RtsCtsReceiver;
	
	components ActiveMessageC;
	
	components new AMSenderC(AM_MY_MSG) as MsgSender;
	components new AMSenderC(AM_RTS_CTS_MSG) as RtsCtsSender;
	
	components new TimerMilliC() as EndTimer;
	components new TimerMilliC() as MilliTimer;
	components new TimerMilliC() as SendReportTimer;


	App.Boot -> MainC.Boot;
	
	App.MsgReceiver -> MsgReceiver;
	App.RtsCtsReceiver -> RtsCtsReceiver;
	
	App.RtsCtsSend -> RtsCtsSender;
	App.MsgSend -> MsgSender;
	
	App.RtsCtsPacket -> RtsCtsSender;
	App.MsgPacket -> MsgSender;
	
	App.SplitControl -> ActiveMessageC;
	App.EndTimer -> EndTimer;
	App.MilliTimer -> MilliTimer;
	App.SendReportTimer -> SendReportTimer;
}

