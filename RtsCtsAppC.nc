#include "RtsCts.h"

configuration RtsCtsAppC {}

implementation {

	components MainC, RtsCtsC as App;
	components new AMReceiverC(AM_MY_MSG);
	components ActiveMessageC;
	components new AMSenderC(AM_MY_MSG);
	
	components new TimerMilliC() as EndTimer;
	components new TimerMilliC() as MilliTimer2;
	components new TimerMilliC() as MilliTimer3;
	components new TimerMilliC() as MilliTimer4;
	components new TimerMilliC() as MilliTimer5;
	components new TimerMilliC() as MilliTimer6;

	App.Boot -> MainC.Boot;
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.SplitControl -> ActiveMessageC;
	App.Packet -> AMSenderC;
	
	App.EndTimer -> EndTimer;
	App.MilliTimer2 -> MilliTimer2;
	App.MilliTimer3 -> MilliTimer3;
	App.MilliTimer4 -> MilliTimer4;
	App.MilliTimer5 -> MilliTimer5;
	App.MilliTimer6 -> MilliTimer6;
}


