/**
 * 	locked: It is true during the sending phase until it finishes
 * 	rts_cts_locked: It is true depeding on the RTS/CTS mechanism
 *	msg_count: Keeps track of the number of messages sent by a mote
 *	report_count: Keeps track of the number of the received reports
 *
 */

#include "RtsCts.h"
#include <stdlib.h>
#include "Timer.h"

module RtsCtsC {

	uses {
		interface Boot;
		interface SplitControl;
		
		interface Packet as RtsCtsPacket;
		interface Packet as MsgPacket;
		
		interface AMSend as MsgSend;
		interface AMSend as RtsCtsSend;
		
		interface Receive as RtsCtsReceiver;
		interface Receive as MsgReceiver;
		
		interface Timer<TMilli> as EndTimer;
		interface Timer<TMilli> as SendReportTimer;
		interface Timer<TMilli> as MilliTimer;
	}

} implementation {

	bool locked;
	bool rts_cts_locked;
	uint16_t msg_count = 0;
	uint16_t report_count = 0;
	uint16_t received_packets[5] = { 0 };
	
	//Constants
	const uint32_t NAV_TIME = 1000; 
	const bool RTS_CTS_ENABLED = TRUE;
	const uint32_t SIMULATION_MAX_TIME = (500*60*10)+100;
	const float LAMBDA_VALUES[5] = { 1.0 , 1.7, 4.2, 2.5, 3.3 };
	
	//Buffer variables
	message_t packet;
	uint8_t i;
	uint16_t not_arrived_packets;
	
	
	void sendRtsCts(bool cts);
	void sendMsg(bool report);
	uint32_t ran_expo(float lambda);
	void startTimer();
	
	
	//***************** Random milliseconds generator by an exp distribution ********************//
	uint32_t ran_expo(float lambda){
    	float u = rand() / (RAND_MAX + 1.0);
    	return (-log(1 - u) / lambda)*1000;
	}

  	//***************** Task send request ********************//
	void sendMsg(bool report) {
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
			if (report) {
				mess->report = 1;
				mess->msg_count = msg_count;
			} else {
				mess->report = 0;
				mess->msg_count = ++msg_count;
			}
			

			dbg("radio_send", "Try to send a message %s \n", sim_time_string());
			if(call MsgSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
				dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call MsgPacket.payloadLength(&packet));
				dbg_clear("radio_pack","\t\t Payload \n" );
				dbg_clear("radio_pack", "\t\t msg_count: %u \n", mess->msg_count);
				dbg_clear("radio_pack", "\t\t sender_id: %u \n", mess->sender_id);
				if (report) {
					dbg_clear("radio_pack", "\t\t message type: REPORT\n");
				} else {
					dbg_clear("radio_pack", "\t\t message type: NORMAL\n");
				}
				dbg_clear("radio_pack", "\n");
			}
		}
	}
	
	//***************** Task send RtsCts ********************//
	void sendRtsCts(bool cts) {
		if (locked) {
			dbgerror("radio_send","Error during sendRts, channel is locked!\n");
			return;
		} else {
			rts_cts_msg_t* rts_cts = (rts_cts_msg_t*)(call RtsCtsPacket.getPayload(&packet,sizeof(rts_cts_msg_t)));
			if (rts_cts == NULL) {
				dbgerror("radio_send","Error during sendRtsCts, rts_cts is NULL!\n");
				return;
			}
			rts_cts->sender_id = TOS_NODE_ID;
	
			if (cts) {
				dbg("radio_send", "[CTS] Try to send a request %s \n", sim_time_string());
				if(call RtsCtsSend.send(AM_BROADCAST_ADDR, &packet,sizeof(rts_cts_msg_t)) == SUCCESS) {
					locked = TRUE;
					dbg("radio_send", "Packet passed to lower layer successfully!\n");
					dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call RtsCtsPacket.payloadLength(&packet));
					dbg_clear("radio_pack","\t\t Payload \n" );
					dbg_clear("radio_pack", "\t\t sender_id: %u \n", rts_cts->sender_id);
					if (cts) {
						dbg_clear("radio_pack", "\t\t message type: CTS");
					} else {
						dbg_clear("radio_pack", "\t\t message type: RTS");
					}
					dbg_clear("radio_pack", "\n");
				}
			} else {
				dbg("radio_send", "[RTS] Try to send a request %s \n", sim_time_string());
				if(call RtsCtsSend.send(1, &packet,sizeof(rts_cts_msg_t)) == SUCCESS) {
					locked = TRUE;
					dbg("radio_send", "Packet passed to lower layer successfully!\n");
					dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call RtsCtsPacket.payloadLength(&packet));
					dbg_clear("radio_pack","\t\t Payload \n" );
					dbg_clear("radio_pack", "\t\t sender_id: %u \n", rts_cts->sender_id);
					if (cts) {
						dbg_clear("radio_pack", "\t\t message type: CTS\n");
					} else {
						dbg_clear("radio_pack", "\t\t message type: RTS\n");
					}
					dbg_clear("radio_pack", "\n");
				}
			}
			
		}
	}
	
  	//***************** Boot interface ********************//
	event void Boot.booted() {
		dbg("boot","Application booted.\n");
		call SplitControl.start();
	}
	
	void startTimer() {
		call MilliTimer.startOneShot(ran_expo(LAMBDA_VALUES[TOS_NODE_ID-2]));
	}
	
 	//***************** SplitControl interface ********************//
	event void SplitControl.startDone(error_t err){
		//Start SIMULATION_MAX_TIME timer
		call EndTimer.startOneShot(SIMULATION_MAX_TIME);
		if(err == SUCCESS) {
			dbg("radio","Radio on at time %lld \n", sim_time());
			if (TOS_NODE_ID != 1) {
				startTimer();
				call SendReportTimer.startOneShot(SIMULATION_MAX_TIME+TOS_NODE_ID*100);
			}
		} else {
			dbgerror("radio","Radio error!\n");
			call SplitControl.start();
		}
	}

	event void SplitControl.stopDone(error_t err){}

	event void MilliTimer.fired() {
		sendMsg(0);
		startTimer();
	}
	
	event void SendReportTimer.fired() {
		
		sendMsg(1);
	}
	
	event void EndTimer.fired() {
		if (TOS_NODE_ID == 1) {
			dbg("radio",">>> Simulation terminated after: %lu seconds <<< \n", SIMULATION_MAX_TIME/1000);	
			dbg("radio",">>> Sending the Report Messages <<< \n\n");	
		} else {
			call MilliTimer.stop();
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
	
	//********************* RtsSend interface ****************//
	event void RtsCtsSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
			dbg_clear("radio_send", "\n");
		} else {
			dbgerror("radio_send","Error in RtsCtsSend.sendDone!\n");
		}
	}
	
  	//***************************** MsgReceive interface *****************//
	event message_t* MsgReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(my_msg_t)) {
			my_msg_t* mess = (my_msg_t*)payload;
			dbg("radio_rec","Message received at time %s \n", sim_time_string());	
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call MsgPacket.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Details\n" );
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", mess->sender_id);
			dbg_clear("radio_pack", "\t\t Is report: %hhu \n", mess->report);
			if (mess->report) {		
				dbg_clear("radio_pack", "\t\t Expected packets: %u \n", mess->msg_count);
				i = mess->sender_id - 2;
				dbg_clear("radio_pack", "\t\t Received packets: %u \n", received_packets[i]);
				not_arrived_packets = mess->msg_count - received_packets[i];
				dbg_clear("radio", "\t\t Not arrived packets: %u \n", not_arrived_packets);
				dbg_clear("radio", "\t\t Packet Error Rate: %f \n", (float)not_arrived_packets/mess->msg_count);
				dbg("radio_rec","This is the %u report correctly received. \n\n", ++report_count);
			} else {
				dbg_clear("radio_pack", "\t\t msg_count: %u \n", mess->msg_count);
				dbg("radio_rec","This is the %u message correctly received by this node. \n\n", ++received_packets[(mess->sender_id)-2]);
			}
		}
		return buf;
	}
	
	//***************************** RtsReceive interface *****************//
	event message_t* RtsCtsReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(rts_cts_msg_t)) {
			rts_cts_msg_t* rts_cts = (rts_cts_msg_t*)payload;
			dbg("radio_rec","[RTS/CTS] Message received at time %s \n", sim_time_string());	
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call RtsCtsPacket.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Payload \n" );
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", rts_cts->sender_id);
			if (rts_cts->cts) {
				dbg_clear("radio_pack", "\t\t message type: CTS\n");
			} else {
				dbg_clear("radio_pack", "\t\t message type: RTS\n");
			}
			dbg_clear("radio_pack", "\n");
		}
		return buf;
	}
}
