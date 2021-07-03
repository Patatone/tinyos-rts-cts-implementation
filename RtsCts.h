/**
 * 	NULL_VAL: Used we don't want to compile a field of a function
 *	report: it is 0 if it's not a report message 1 otherwise 
 * 	type: it is 0 if it's a rts message 1 if it's a cts message 
 */
 
#ifndef RTSCTS_H
#define RTSCTS_H

#define RTS 0
#define CTS 1

typedef nx_struct my_msg {
	nx_uint16_t msg_count;
	nx_uint8_t sender_id;
	nx_uint8_t report;
} my_msg_t;

typedef nx_struct rts_cts_msg {
	nx_uint8_t sender_id;
	nx_uint8_t type;
} rts_cts_msg_t;

enum{
	AM_MY_MSG = 6,
	AM_RTS_CTS_MSG = 6,
};

#endif
