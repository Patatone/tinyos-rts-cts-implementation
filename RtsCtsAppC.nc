#include "RtsCts.h"

configuration RtsCtsAppC {}

implementation {

	components MainC, RtsCtsC as App;
	components new AMReceiverC(AM_MY_MSG);
	components ActiveMessageC;
	components new AMSenderC(AM_MY_MSG);
	components new TimerMilliC();

	App.Boot -> MainC.Boot;
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.SplitControl -> ActiveMessageC;
	App.Packet -> AMSenderC;
	App.MilliTimer -> TimerMilliC;
}

