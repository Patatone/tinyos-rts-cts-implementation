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
	uint16_t msg_id = 0;
	uint16_t error_count[5] = {0};
	const uint32_t SIMULATION_MAX_TIME = 1000*60*10;
	
	//Buffer variables
	message_t packet;
	uint8_t i;
	
	void sendReq();
	void sendResp();

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
				dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet) );
				dbg_clear("radio_pack","\t\t Payload \n" );
				dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
				dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
				dbg_clear("radio_pack", "\t\t sender_id: %hhu \n", mess->sender_id);
				dbg_clear("radio_pack", "\n");
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
				call MilliTimer2.startPeriodic(2000);
				break;
				case 3:
				call MilliTimer3.startPeriodic(3000);
				break;
				case 4:
				call MilliTimer4.startPeriodic(4000);
				break;
				case 5:
				call MilliTimer5.startPeriodic(5000);
				break;
				case 6:
				call MilliTimer6.startPeriodic(1000);
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
			dbg("radio",">>> Simulation terminated after: %lu seconds. <<<\n", SIMULATION_MAX_TIME/1000);	
			for (i = 0; i < 5; ++i) {
				dbg("radio","> Stats for the node: %u \n", i+2);
				dbg_clear("radio", "\t\t Errors number: %hhu \n", error_count[i]);
				dbg_clear("radio", "\t\t Error ratio: %f \n", error_count[i]/SIMULATION_MAX_TIME);
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
		if (len != sizeof(my_msg_t)) {
			dbgerror("radio_rec","Error receiving a packet!\n");
			return buf;
		} else {
			my_msg_t* mess = (my_msg_t*)payload;
			
			dbg("radio_rec","Message received at time %s \n", sim_time_string());
			dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength(buf));
			dbg_clear("radio_pack","\t\t Payload \n");
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
			dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
			dbg_clear("radio_pack", "\t\t sender_id: %hhu \n", mess->sender_id);
			dbg_clear("radio_pack", "\n");
/*		if (mess->msg_type == REQ) {
			sendResp();
		}*/
			return buf;
		}
	}

}
