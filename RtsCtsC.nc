/**
 * 	locked: It is true during the sending phase until it finishes
 * 	rts_cts_locked: It is true depeding on the RTS/CTS mechanism
 *
 */

#include "RtsCts.h"
#include "Timer.h"

module RtsCtsC {

	uses {
		interface Boot;
		interface Packet;
		interface AMSend;
		interface SplitControl;
		interface Receive;
		
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
	
	const uint32_t NAV_TIME = 1000; 
	const bool RTS_CTS_ENABLED = TRUE;
	const uint32_t SIMULATION_MAX_TIME = (1000*60*10)+100;
	const uint16_t MOTES_RATE[] = { 1000*2, 1000*3, 1000*4, 1000*5, 1000*1 };
	
	//Buffer variables
	message_t packet;
	uint8_t i;
	uint16_t expected_packets;
	uint16_t not_arrived_packets;
	
	
	void sendRtsCts(uint8_t msg_type);
	void sendReq();
	void sendResp();
	void printPacket(uint8_t t_msg_type, uint16_t t_msg_id, uint16_t t_sender_id, message_t* buf);
	
	
	//***************** Simple function to print the packet ********************//
	void printPacket(uint8_t t_msg_type, uint16_t t_msg_id, uint16_t t_sender_id, message_t* buf) {
		if (buf != FIELD_NOT_USED)
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call Packet.payloadLength(buf));
		else 
			dbg("radio_pack",">>>Pack\n \t Payload length %u \n", call Packet.payloadLength(&packet));
		dbg_clear("radio_pack","\t\t Payload \n" );
		if (t_msg_type != FIELD_NOT_USED)
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", t_msg_type);
		if (t_msg_id != FIELD_NOT_USED)
			dbg_clear("radio_pack", "\t\t msg_id: %u \n", t_msg_id);
		if (t_sender_id != FIELD_NOT_USED)
			dbg_clear("radio_pack", "\t\t sender_id: %u \n", t_sender_id);
		dbg_clear("radio_pack", "\n");
	}
	
  	//***************** Task send request ********************//
	void sendReq() {
		if (locked) {
			dbgerror("radio_send","Error during sendReq, channel is locked!\n");
			return;
		} else {
			my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
			if (mess == NULL) {
				dbgerror("radio_send","Error during sendReq, mess is NULL!\n");
				return;
			}
			mess->sender_id = TOS_NODE_ID;
			mess->msg_type = REQ;
			mess->msg_id = ++msg_id;

			dbg("radio_send", "Try to send a message %s \n", sim_time_string());
			if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
				printPacket(mess->msg_type, mess->msg_id, mess->sender_id, FIELD_NOT_USED);
			}
		}
	}
	
	//***************** Task send RTS/CTS ********************//
	void sendRtsCts(uint8_t msg_type) {
		if (locked) {
			dbgerror("radio_send","Error during sendReq, channel is locked!\n");
			return;
		} else {
			rts_cts_msg_t* mess=(rts_cts_msg_t*)(call Packet.getPayload(&packet,sizeof(rts_cts_msg_t)));
			if (mess == NULL) {
				dbgerror("radio_send","Error during sendReq, mess is NULL!\n");
				return;
			}
			mess->sender_id = TOS_NODE_ID;
			mess->msg_type = msg_type;

			dbg("radio_send", "[RTS/CTS] Try to send a request %s \n", sim_time_string());
			if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS) {
				locked = TRUE;
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
				printPacket(mess->msg_type, FIELD_NOT_USED, mess->sender_id, FIELD_NOT_USED);
			}
		}
	}
	
  //****************** Task send response *****************//
	void sendResp() {

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
		sendReq();
	}

	event void MilliTimer3.fired() {
		sendReq();
	}

	event void MilliTimer4.fired() {
		sendReq();
	}

	event void MilliTimer5.fired() {
		sendReq();
	}

	event void MilliTimer6.fired() {
		sendReq();
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

  //********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {
		if(&packet == buf && err == SUCCESS) {
			locked = FALSE;
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
			dbg_clear("radio_send", "\n");
		} else {
			dbgerror("radio_send","Error in AMSend.sendDone!\n");
		}
	}

  //***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		if (len == sizeof(my_msg_t)) {
			my_msg_t* mess = (my_msg_t*)payload;
			dbg("radio_rec","Massage received at time %s \n", sim_time_string());
			dbg("radio_rec","This is the %u message correctly received by this node. \n", ++received_packets[(mess->sender_id)-2]);
			printPacket(mess->msg_type, mess->msg_id, mess->sender_id, buf);
		} else if (len == sizeof(rts_cts_msg_t)) {
			rts_cts_msg_t* mess = (rts_cts_msg_t*)payload;
			dbg("radio_rec","[RTS/CTS] Request received at time %s \n", sim_time_string());
			printPacket(mess->msg_type, FIELD_NOT_USED, mess->sender_id, buf);
		} else {
			dbgerror("radio_rec","Error receiving a packet!\n");
		}
/*		
		if (mess->msg_type == REQ) {
			sendResp();
		}   
*/
		return buf;
	}

}
