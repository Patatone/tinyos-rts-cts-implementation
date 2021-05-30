/**
 * 	locked: It is true during the sending phase until it finishes
 * 	rts_cts_locked: It is true depeding on the RTS/CTS mechanism
 *
 */

#include "RtsCts.h"
#include <stdlib.h>
#include "Timer.h"

module RtsCtsC {

	uses {
		interface Boot;
		interface SplitControl;
		
		interface Packet as RtsPacket;
		interface Packet as CtsPacket;
		interface Packet as MsgPacket;
		interface Packet as ReportPacket;
		
		interface AMSend as MsgSend;
		interface AMSend as RtsSend;
		interface AMSend as CtsSend;
		interface AMSend as ReportSend;
		
		interface Receive as RtsReceiver;
		interface Receive as CtsReceiver;
		interface Receive as MsgReceiver;
		interface Receive as ReportReceiver;
		
		interface Timer<TMilli> as EndTimer;
		interface Timer<TMilli> as MilliTimer2;
		interface Timer<TMilli> as MilliTimer3;
		interface Timer<TMilli> as MilliTimer4;
		interface Timer<TMilli> as MilliTimer5;
		interface Timer<TMilli> as MilliTimer6;
	}

} implementation {

	bool locked;
	bool rts_cts_locked;
	uint16_t msg_id = 0;
	uint16_t received_packets[5] = { 0 };
	
	//Constants
	const uint32_t NAV_TIME = 1000; 
	const bool RTS_CTS_ENABLED = TRUE;
	const uint32_t SIMULATION_MAX_TIME = (1000*60*10)+100;
	const uint16_t MOTES_RATE[] = { 1000*2, 1000*3, 1000*4, 1000*5, 1000*1 };
	const double LAMBDA_VALUES[5] = { 0.05, 0.06, 0.07, 0.02, 0.01 };
	
	//Buffer variables
	message_t packet;
	uint8_t i;
	uint16_t expected_packets;
	uint16_t not_arrived_packets;
	
	
	void sendCts();
	void sendRts();
	void sendMsg();
	double ran_expo(double lambda);
	
	
	//***************** Random number by an exp distribution ********************//
	double ran_expo(double lambda){
    	double u;
    	u = rand() / (RAND_MAX + 1.0);
    	return -log(1 - u) / lambda;
	}

  	//***************** Task send request ********************//
	void sendMsg() {
		if (locked) {
			dbgerror("radio_send","Error during sendMsg, channel is locked!\n");
			return;
		} else {
			my_msg_t* mess=(my_msg_t*)(call MsgPacket.getPayload(&packet,sizeof(my_msg_t)));
			if (mess == NULL) {
				dbgerror("radio_send","Error during sendMsg, mess is NULL!\n");
				return;
			}
			mess->sender_id = TOS_NODE_ID;
			mess->msg_id = ++msg_id;

			dbg("radio_send", "Try to send a message %s \n", sim_time_string());
			if(call MsgSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
				dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call MsgPacket.payloadLength(&packet));
				dbg_clear("radio_pack","\t\t Payload \n" );
				dbg_clear("radio_pack", "\t\t msg_id: %u \n", mess->msg_id);
				dbg_clear("radio_pack", "\t\t sender_id: %u \n", mess->sender_id);
				dbg_clear("radio_pack", "\n");
			}
		}
	}
	
	//***************** Task send Rts ********************//
	void sendRts() {
		if (locked) {
			dbgerror("radio_send","Error during sendRts, channel is locked!\n");
			return;
		} else {
			rts_msg_t* rts = (rts_msg_t*)(call RtsPacket.getPayload(&packet,sizeof(rts_msg_t)));
			if (rts == NULL) {
				dbgerror("radio_send","Error during sendRts, rts is NULL!\n");
				return;
			}
			rts->sender_id = TOS_NODE_ID;

			dbg("radio_send", "[RTS] Try to send a request %s \n", sim_time_string());
			if(call RtsSend.send(1, &packet,sizeof(rts_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
				dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call RtsPacket.payloadLength(&packet));
				dbg_clear("radio_pack","\t\t Payload \n" );
				dbg_clear("radio_pack", "\t\t sender_id: %u \n", rts->sender_id);
				dbg_clear("radio_pack", "\n");
			}
		}
	}

	void sendCts() {
		if (locked) {
			dbgerror("radio_send","Error during sendCts, channel is locked!\n");
			return;
		} else {
			cts_msg_t* cts = (cts_msg_t*)(call CtsPacket.getPayload(&packet,sizeof(cts_msg_t)));
			if (cts == NULL) {
				dbgerror("radio_send","Error during sendCts, cts is NULL!\n");
				return;
			}
			cts->sender_id = TOS_NODE_ID;

			dbg("radio_send", "[CTS] Try to send a request %s \n", sim_time_string());
			if(call CtsSend.send(AM_BROADCAST_ADDR, &packet,sizeof(cts_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
				dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call CtsPacket.payloadLength(&packet));
				dbg_clear("radio_pack","\t\t Payload \n" );
				dbg_clear("radio_pack", "\t\t sender_id: %u \n", cts->sender_id);
				dbg_clear("radio_pack", "\n");
			}
		}
	}
	
  	//***************** Boot interface ********************//
	event void Boot.booted() {
		dbg("boot","Application booted.\n");
		call SplitControl.start();
	}

 	//***************** SplitControl interface ********************//
	event void SplitControl.startDone(error_t err){
		//Start 10 minutes timer
		call EndTimer.startOneShot(SIMULATION_MAX_TIME);
		if(err == SUCCESS) {
			dbg("radio","Radio on at time %lld \n", sim_time());
			switch (TOS_NODE_ID) {
				case 2:
				call MilliTimer2.startPeriodic(MOTES_RATE[0]);
				break;
				case 3:
				call MilliTimer3.startPeriodic(MOTES_RATE[1]);
				break;
				case 4:
				call MilliTimer4.startPeriodic(MOTES_RATE[2]);
				break;
				case 5:
				call MilliTimer5.startPeriodic(MOTES_RATE[3]);
				break;
				case 6:
				call MilliTimer6.startPeriodic(MOTES_RATE[4]);
				break;
			}
		} else {
			dbgerror("radio","Radio error!\n");
			call SplitControl.start();
		}
	}

	event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimerN interfaces ********************//
	event void MilliTimer2.fired() {
		sendMsg();
	}

	event void MilliTimer3.fired() {
		sendMsg();
	}

	event void MilliTimer4.fired() {
		sendMsg();
	}

	event void MilliTimer5.fired() {
		sendMsg();
	}

	event void MilliTimer6.fired() {
		sendMsg();
	}
	
	event void EndTimer.fired() {
		switch (TOS_NODE_ID) {
			case 1:
			dbg_clear("radio", "\n\n");
			dbg("radio",">>> Simulation terminated after: %lu seconds <<< \n\n", SIMULATION_MAX_TIME/1000);	
			for (i = 0; i < 5; ++i) {
				dbg("radio","> Stats for the node: %u \n", i+2);
				expected_packets = (uint16_t)(SIMULATION_MAX_TIME/MOTES_RATE[i]);
				dbg_clear("radio", "\t\t Expected packets: %u \n", expected_packets);
				dbg_clear("radio", "\t\t Received packets: %u \n", received_packets[i]);
				not_arrived_packets = expected_packets - received_packets[i];
				dbg_clear("radio", "\t\t Not arrived packets: %u \n", not_arrived_packets);
				dbg_clear("radio", "\t\t Packet Error Rate: %f \n", (float)not_arrived_packets/expected_packets);
			}
			break;
			case 2:
			call MilliTimer2.stop();
			break;
			case 3:
			call MilliTimer3.stop();
			break;
			case 4:
			call MilliTimer4.stop();
			break;
			case 5:
			call MilliTimer5.stop();
			break;
			case 6:
			call MilliTimer6.stop();
			break;
		}
	}

  	//********************* MsgSend interface ****************//
	event void MsgSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
			dbg_clear("radio_send", "\n");
		} else {
			dbgerror("radio_send","Error in MsgSend.sendDone!\n");
		}
	}

	//********************* CtsSend interface ****************//
	event void CtsSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
			dbg_clear("radio_send", "\n");
		} else {
			dbgerror("radio_send","Error in CtsSend.sendDone!\n");
		}
	}
	
	//********************* RtsSend interface ****************//
	event void RtsSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
			dbg_clear("radio_send", "\n");
		} else {
			dbgerror("radio_send","Error in RtsSend.sendDone!\n");
		}
	}
	
	//********************* RtsSend interface ****************//
	event void ReportSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
			dbg_clear("radio_send", "\n");
		} else {
			dbgerror("radio_send","Error in ReportSend.sendDone!\n");
		}
	}
	
  	//***************************** MsgReceive interface *****************//
	event message_t* MsgReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(my_msg_t)) {
			my_msg_t* mess = (my_msg_t*)payload;
			dbg("radio_rec","[MSG] Massage received at time %s \n", sim_time_string());
			dbg("radio_rec","This is the %u message correctly received by this node. \n", ++received_packets[(mess->sender_id)-2]);
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call MsgPacket.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Payload \n" );
			dbg_clear("radio_pack", "\t\t msg_id: %u \n", mess->msg_id);
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", mess->sender_id);
			dbg_clear("radio_pack", "\n");
		}
		return buf;
	}
	
	//***************************** CtsReceive interface *****************//
	event message_t* CtsReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(cts_msg_t)) {
			cts_msg_t* cts = (cts_msg_t*)payload;
			dbg("radio_rec","[CTS] Message received at time %s \n", sim_time_string());	
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call CtsPacket.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Payload \n" );
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", cts->sender_id);
			dbg_clear("radio_pack", "\n");
		}
		return buf;
	}
	
	//***************************** RtsReceive interface *****************//
	event message_t* RtsReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(rts_msg_t)) {
			rts_msg_t* rts = (rts_msg_t*)payload;
			dbg("radio_rec","[RTS] Message received at time %s \n", sim_time_string());	
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call RtsPacket.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Payload \n" );
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", rts->sender_id);
			dbg_clear("radio_pack", "\n");
		}
		return buf;
	}
	
	//***************************** ReportReceive interface *****************//
	event message_t* ReportReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(report_msg_t)) {
			report_msg_t* report = (report_msg_t*)payload;
			dbg("radio_rec","[REPORT] Message received at time %s \n", sim_time_string());	
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call ReportPacket.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Payload \n" );
			dbg_clear("radio_pack", "\t\t message_count: %u \n", report->message_count);
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", report->sender_id);
			dbg_clear("radio_pack", "\n");
		}
		return buf;
	}

}
