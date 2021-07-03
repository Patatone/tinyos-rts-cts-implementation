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
	components new TimerMilliC() as SendMsgTimer;
	components new TimerMilliC() as SimulationEndTimer;
	components new TimerMilliC() as BackOffTimer;
	components new TimerMilliC() as SifsMsgTimer;
	components new TimerMilliC() as SifsCtsTimer;
	
	App.Boot -> MainC.Boot;
	
	App.MsgReceiver -> MsgReceiver;
	App.RtsCtsReceiver -> RtsCtsReceiver;
	
	App.RtsCtsSend -> RtsCtsSender;
	App.MsgSend -> MsgSender;
	
	App.RtsCtsPacket -> RtsCtsSender;
	App.MsgPacket -> MsgSender;
	
	App.SplitControl -> ActiveMessageC;
	App.EndTimer -> EndTimer;
	App.SendMsgTimer -> SendMsgTimer;
	App.SimulationEndTimer -> SimulationEndTimer;
	App.BackOffTimer -> BackOffTimer;
	App.SifsMsgTimer -> SifsMsgTimer;
	App.SifsCtsTimer -> SifsCtsTimer;
}

