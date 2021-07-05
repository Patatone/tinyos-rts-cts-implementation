/**
 *	report: It is 0 if it's not a report message 1 otherwise 
 * 	authorized_node: It defines the node that can transmit
 *
 */
 
#ifndef RTSCTS_H
#define RTSCTS_H

typedef nx_struct my_msg {
	nx_uint16_t msg_count;
	nx_uint8_t sender_id;
	nx_uint8_t report;
} my_msg_t;

typedef nx_struct rts_msg {
	nx_uint8_t sender_id;
} rts_msg_t;

typedef nx_struct cts_msg {
	nx_uint8_t sender_id;
	nx_uint8_t authorized_node;
} cts_msg_t;

enum{
	AM_MY_MSG = 6,
	AM_CTS_MSG = 6,
	AM_RTS_MSG = 6,
};

#endif
