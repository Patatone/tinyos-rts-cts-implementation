/**
 * 	NULL_VAL: Used we don't want to compile a field of a function
 *
 */
 
#ifndef RTSCTS_H
#define RTSCTS_H

typedef nx_struct my_msg {
	nx_uint16_t msg_id;
	nx_uint16_t sender_id;
} my_msg_t;

typedef nx_struct cts_msg {
	nx_uint16_t sender_id;
} cts_msg_t;

typedef nx_struct rts_msg {
	nx_uint16_t sender_id;
} rts_msg_t;

typedef nx_struct report_msg {
	nx_uint16_t message_count;
	nx_uint16_t sender_id;
} report_msg_t;

#define NULL_VAL 0

enum{
	AM_MY_MSG = 6,
	AM_RTS_MSG = 6,
	AM_CTS_MSG = 6,
	AM_REPORT_MSG = 6,
};

#endif
