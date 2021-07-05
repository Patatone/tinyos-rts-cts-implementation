/**
 * 	locked: It is true during the sending phase until it finishes
 * 	back_off: It is true depeding on the RTS/CTS mechanism
 *	msg_count: Keeps track of the number of messages sent by a mote
 *	report_count: Keeps track of the number of the received reports
 *  X: It defines the time to wait after receiving an RTS/CTS message
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
		
		interface AMSend as MsgSend;
		interface AMSend as RtsSend;
		interface AMSend as CtsSend;
		
		interface Receive as RtsReceiver;
		interface Receive as CtsReceiver;
		interface Receive as MsgReceiver;
		
		interface Timer<TMilli> as SimulationEndTimer;
		interface Timer<TMilli> as SendReportTimer;
		interface Timer<TMilli> as SendMsgTimer;
		interface Timer<TMilli> as BackOffTimer;
		interface Timer<TMilli> as SifsCtsTimer;
		interface Timer<TMilli> as SifsMsgTimer;
	}

} implementation {

	//Status variables
	bool locked = FALSE;
	bool back_off = FALSE;
	uint16_t msg_count = 0;
	uint16_t report_count = 0;
	uint16_t received_packets[5] = { 0 };
	
	//Constants
	const uint32_t X = 250; 
	const bool RTS_CTS_ENABLED = TRUE;
	const uint32_t SIMULATION_MAX_TIME = (500*60*10)+100;
	const float LAMBDA_VALUES[5] = { 1.0 , 1.7, 4.2, 2.5, 3.3 };
	
	//Buffer variables
	message_t packet;
	uint8_t i;
	uint8_t authorized_node;
	uint16_t not_arrived_packets;
	

	void sendCts();
	void sendRts();
	void sendMsg(bool report);
	uint32_t ran_expo(float lambda);
	void startTimer();
	void startBackOff();
	void printSpacer();
	
	
	void printSpacer() {
		for (i = 0; i<80; ++i) {
			dbg_clear("general", "-");
		}
		dbg_clear("general", "\n");
	}
	
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
			mess->sender_id = (uint8_t)TOS_NODE_ID;
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
				dbg("radio_pack","Payload\n");
				dbg_clear("radio_pack", "\t Payload length %u \n", call MsgPacket.payloadLength(&packet));
				dbg_clear("radio_pack", "\t msg_count: %u \n", mess->msg_count);
				dbg_clear("radio_pack", "\t sender_id: %hhu \n", mess->sender_id);
				if (report) {
					dbg_clear("radio_pack", "\t message type: REPORT\n");
				} else {
					dbg_clear("radio_pack", "\t message type: NORMAL\n");
				}
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
			
			rts->sender_id = (uint8_t)TOS_NODE_ID;
	
			if(call RtsSend.send(AM_BROADCAST_ADDR, &packet,sizeof(rts_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "[>>>] Sending a RTS at %s\n", sim_time_string());
			}
	
		}
	}
	
	//***************** Task send Cts ********************//
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
			
			cts->sender_id = (uint8_t)TOS_NODE_ID;
			cts->authorized_node = authorized_node;
			
			if(call CtsSend.send(AM_BROADCAST_ADDR, &packet,sizeof(cts_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "[>>>] Sending a CTS(node: %hhu) at %s\n", cts->authorized_node, sim_time_string());
			}
	
		}
	}
  	//***************** Boot interface ********************//
	event void Boot.booted() {
		dbg("boot","Application booted.\n");
		
		call SplitControl.start();
	}
	
	void startTimer() {
		call SendMsgTimer.startOneShot(ran_expo(LAMBDA_VALUES[TOS_NODE_ID-2]));
	}
	
 	//***************** SplitControl interface ********************//
	event void SplitControl.startDone(error_t err){
		call SimulationEndTimer.startOneShot(SIMULATION_MAX_TIME);
		if(err == SUCCESS) {
			dbg("radio","Radio on at time %s \n", sim_time_string());
			if (TOS_NODE_ID != 1) {
				dbg_clear("radio", "Using labda=%f and X=%lu\n", LAMBDA_VALUES[TOS_NODE_ID-2], X);
				startTimer();
				call SendReportTimer.startOneShot(SIMULATION_MAX_TIME+TOS_NODE_ID*100);
			}
		} else {
			dbgerror("radio","Radio error!\n");
			call SplitControl.start();
		}
	}

	event void SplitControl.stopDone(error_t err){}

	event void SendMsgTimer.fired() {
		dbg("timer", "SendMsgTimer fired at time %s. ", sim_time_string());
		if (RTS_CTS_ENABLED) {
			if (back_off) {
				dbg_clear("timer","Backoff period\n");
				startTimer();
			} else {
				dbg_clear("timer","Possibility to send\n");
				sendRts();
			}
		} else {
			dbg_clear("timer","\n");
			sendMsg(0);
		}
	}
	
	event void SendReportTimer.fired() {
		sendMsg(1);
	}
	
	event void SimulationEndTimer.fired() {
		if (TOS_NODE_ID == 1) {
			if (RTS_CTS_ENABLED) {
				call SifsCtsTimer.stop();
			}
			printSpacer();
			dbg("radio",">>> Simulation terminated after: %lu seconds <<< \n", SIMULATION_MAX_TIME/1000);	
			dbg("radio",">>> Sending the Report Messages <<< \n\n");	
		} else {
			call SendMsgTimer.stop();
			if (RTS_CTS_ENABLED) {
				call SifsMsgTimer.stop();
				call BackOffTimer.stop();
			}
		}
	}
	
  	//********************* MsgSend interface ****************//
	event void MsgSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "[>>>] Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		} else {
			dbgerror("radio_send","Error in MsgSend.sendDone!\n");
		}
		printSpacer();
		if (call SimulationEndTimer.isRunning()) {
			startTimer();
		}
	}
	
	//********************* RtsSend interface ****************//
	event void RtsSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "[>>>] Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		} else {
			dbgerror("radio_send","Error in RtsSend.sendDone!\n");
		}
	}
	
	//********************* CtsSend interface ****************//
	event void CtsSend.sendDone(message_t* buf, error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "[>>>] Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		} else {
			dbgerror("radio_send","Error in CtsSend.sendDone!\n");
		}
	}
	
  	//***************************** MsgReceive interface *****************//
	event message_t* MsgReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(my_msg_t)) {
			my_msg_t* mess = (my_msg_t*)payload;
			if (!call SimulationEndTimer.isRunning() && !mess->report) {
				return buf;
			}
			dbg("radio_rec","[<<<] Message received at time %s \n", sim_time_string());	
			dbg("radio_pack","Details\n");
			dbg_clear("radio_pack", "\t Payload length %u \n", call MsgPacket.payloadLength(buf));
			dbg_clear("radio_pack", "\t sender_id: %hhu \n", mess->sender_id);
			dbg_clear("radio_pack", "\t Is report: %hhu \n", mess->report);
			if (mess->report) {		
				dbg_clear("radio_pack", "\t Expected packets: %u \n", mess->msg_count);
				i = mess->sender_id - 2;
				dbg_clear("radio_pack", "\t Received packets: %u \n", received_packets[i]);
				not_arrived_packets = mess->msg_count - received_packets[i];
				dbg_clear("radio", "\t Not arrived packets: %u \n", not_arrived_packets);
				dbg_clear("radio", "\t Packet Error Rate: %f \n", (float)not_arrived_packets/mess->msg_count);
				dbg("radio_rec","This is the %u report correctly received. \n\n", ++report_count);
			} else {
				dbg_clear("radio_pack", "\t msg_count: %u \n", mess->msg_count);
				dbg("radio_rec","This is the %u message correctly received from node %u. \n\n", ++received_packets[(mess->sender_id)-2], mess->sender_id);
			}
		}
		return buf;
	}
	
	//***************** Required to avoid collisions ********************//
	event void SifsMsgTimer.fired() {
		sendMsg(0);
	}
	
	//***************** Required to avoid collisions ********************//
	event void SifsCtsTimer.fired() {
		sendCts();
	}
	
	//***************** Start the Back Off, someone have to transmit ********************//
	void startBackOff() {
		back_off = TRUE;
		call BackOffTimer.startOneShot(X);
	}
	
	//***************** When the backoff period ends, we can have new transmissions ********************//
	event void BackOffTimer.fired() {
		dbg("timer", "Back off period finished at %s.\n", sim_time_string());
		back_off = FALSE;
		if (!call SendMsgTimer.isRunning()) {
			startTimer();
		}
	}
	
	//***************************** RtsReceive interface *****************//
	event message_t* RtsReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(rts_msg_t)) {
			rts_msg_t* rts = (rts_msg_t*)payload;
			if (!call SimulationEndTimer.isRunning()) {
				return buf;
			}	
			dbg("radio_rec","[<<<] Received a RTS from %hhu at time %s. ", rts->sender_id, sim_time_string());
				if (TOS_NODE_ID == 1) {
					if (!back_off) {
						dbg_clear("radio_rec", "Ready to send the CTS(node: %hhu).\n", rts->sender_id);
						authorized_node = rts->sender_id;
						startBackOff();
						call SifsCtsTimer.startOneShot(8);
					} else {
						dbg_clear("radio_rec", "Request by node: %hhu rejected.\n", rts->sender_id);
					}
				} else {
					dbg_clear("radio_rec", "Starting a back off.\n");
					startBackOff();
				}
		}
		return buf;
	}
	
	//***************************** CtsReceive interface *****************//
	event message_t* CtsReceiver.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(cts_msg_t)) {
			cts_msg_t* cts = (cts_msg_t*)payload;
			if (!call SimulationEndTimer.isRunning()) {
				return buf;
			}	
			dbg("radio_rec","[<<<] Received a CTS(node: %hhu) from %hhu at time %s. ", cts->authorized_node, cts->sender_id, sim_time_string());
			if (cts->authorized_node == (uint8_t)TOS_NODE_ID) {
				dbg_clear("radio_rec", "Ready to send the message.\n");
				call SifsMsgTimer.startOneShot(8);
			} else if (!back_off) {
				dbg_clear("radio_rec", "Starting a back off.\n");
				startBackOff();
			} else {
				dbg_clear("radio_rec", "Already in back off.\n");
			}
		}
		return buf;
	}
}
