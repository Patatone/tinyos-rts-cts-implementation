#include "RtsCts.h"

configuration RtsCtsAppC {}

implementation {

	components MainC, RtsCtsC as App;
	
	components new AMReceiverC(AM_MY_MSG) as MsgReceiver;
	components new AMReceiverC(AM_CTS_MSG) as CtsReceiver;
	components new AMReceiverC(AM_RTS_MSG) as RtsReceiver;
	
	components ActiveMessageC;
	
	components new AMSenderC(AM_MY_MSG) as MsgSender;
	components new AMSenderC(AM_CTS_MSG) as CtsSender;
	components new AMSenderC(AM_RTS_MSG) as RtsSender;
	
	components new TimerMilliC() as SimulationEndTimer;
	components new TimerMilliC() as SendMsgTimer;
	components new TimerMilliC() as SendReportTimer;
	components new TimerMilliC() as BackOffTimer;
	components new TimerMilliC() as SifsMsgTimer;
	components new TimerMilliC() as SifsCtsTimer;
	
	App.Boot -> MainC.Boot;
	
	App.MsgReceiver -> MsgReceiver;
	App.CtsReceiver -> CtsReceiver;
	App.RtsReceiver -> RtsReceiver;
	
	App.CtsSend -> CtsSender;
	App.RtsSend -> RtsSender;
	App.MsgSend -> MsgSender;
	
	App.CtsPacket -> CtsSender;
	App.RtsPacket -> RtsSender;
	App.MsgPacket -> MsgSender;
	
	App.SplitControl -> ActiveMessageC;
	App.SimulationEndTimer -> SimulationEndTimer;
	App.SendMsgTimer -> SendMsgTimer;
	App.SendReportTimer -> SendReportTimer;
	App.BackOffTimer -> BackOffTimer;
	App.SifsMsgTimer -> SifsMsgTimer;
	App.SifsCtsTimer -> SifsCtsTimer;
}

